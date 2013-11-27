fs = require 'fs'
assert = require 'assert'
colors = require 'colors'
http = require 'http'
crypto = require 'crypto'
express = require 'express'
expressResource = require 'express-resource'  # required for koality-api-server
request = require 'request'
csrf = require './csrf'
gzip = require './gzip'

ResourceConnection = require 'koality-resource-connection'
StaticServer = require 'koality-static-server'
ApiServer = require 'koality-api-server'

SessionStore = require './stores/sessionStore'
CreateAccountStore = require './stores/createAccountStore'

IndexHandler = require './handlers/indexHandler'
InstallationWizardHandler = require './handlers/installationWizardHandler'
UnexpectedErrorHandler = require './handlers/unexpectedErrorHandler'
InvalidPermissionsHandler = require './handlers/invalidPermissionsHandler'


exports.create = (configurationParams, modelConnection, gitHubConnection, mailer, logger) ->
	stores =
		sessionStore: SessionStore.create configurationParams
		createAccountStore: CreateAccountStore.create configurationParams
	
	cookieName = 'koality.session.id'
	resourceConnection = ResourceConnection.create modelConnection, stores, gitHubConnection, cookieName, mailer, logger
	
	staticServer = StaticServer.create()
	apiServer = ApiServer.create modelConnection, logger

	filesSuffix = '_' + (new Date()).getTime().toString 36
	handlers =
		indexHandler: IndexHandler.create configurationParams, stores, modelConnection.rpcConnection, filesSuffix, logger
		installationWizardHandler: InstallationWizardHandler.create configurationParams, stores, modelConnection.rpcConnection, filesSuffix, logger
		unexpectedErrorHandler: UnexpectedErrorHandler.create configurationParams, stores, modelConnection.rpcConnection, filesSuffix, logger
		invalidPermissionsHandler: InvalidPermissionsHandler.create configurationParams, stores, modelConnection.rpcConnection, filesSuffix, logger

	return new Server configurationParams, cookieName, modelConnection, resourceConnection, stores, handlers, staticServer, apiServer, logger


class Server
	constructor: (@configurationParams, @cookieName, @modelConnection, @resourceConnection, @stores, @handlers, @staticServer, @apiServer, @logger) ->
		assert.ok typeof @configurationParams is 'object'
		assert.ok typeof @cookieName is 'string'
		assert.ok typeof @modelConnection is 'object'
		assert.ok typeof @resourceConnection is 'object'
		assert.ok typeof @stores is 'object'
		assert.ok typeof @handlers is 'object'
		assert.ok typeof @staticServer is 'object'
		assert.ok typeof @apiServer is 'object'
		assert.ok typeof @logger is 'object'


	initialize: (callback) =>
		@_initializeHandlers (error) =>
			if error? then callback error
			else @_initializeStaticServer callback


	_initializeHandlers: (callback) =>
		# if this seciton is causing problems, be sure to increase
		# the maximum number of files you can have open
		errors = {}
		await
			@handlers.indexHandler.initialize defer errors.indexHandlerError
			@handlers.installationWizardHandler.initialize defer errors.insallationWizardHandlerError
			@handlers.unexpectedErrorHandler.initialize defer errors.unexpectedErrorHandlerError
			@handlers.invalidPermissionsHandler.initialize defer errors.invalidPermissionsHandlerError

		combinedErrors = []
		for key, error of errors
			combinedErrors.push error if error?

		if combinedErrors.length > 0
			callback combinedErrors.join ' '
		else
			callback()


	_initializeStaticServer: (callback) =>
		for handlerName, handler of @handlers
			@staticServer.addFiles handler.getFiles()

		callback()


	start: () =>
		addInstallationWizardBindings = () =>
			console.log 'adding installation wizard bindings'.cyan

			expressServer.get '/', @handlers.installationWizardHandler.handleRequest
			expressServer.get '/wizard', @handlers.installationWizardHandler.handleRequest
			expressServer.get '/unexpectedError', @handlers.unexpectedErrorHandler.handleRequest
			expressServer.get '/invalidPermissions', @handlers.invalidPermissionsHandler.handleRequest
			expressServer.post '/turnOffInstallationWizard', turnOffInstallationWizard
			expressServer.get '*', @staticServer.handleRequest

		turnOffInstallationWizard = (request, response) =>
			removeInstallationWizardBindings()
			addProjectBindings()
			response.send 'ok'

		removeInstallationWizardBindings = () =>
			expressServer.routes.get = expressServer.routes.get.filter (route) -> route.path isnt '/'
			expressServer.routes.get = expressServer.routes.get.filter (route) -> route.path isnt '/wizard'
			expressServer.routes.get = expressServer.routes.get.filter (route) -> route.path isnt '/unexpectedError'
			expressServer.routes.get = expressServer.routes.get.filter (route) -> route.path isnt '/invalidPermissions'
			expressServer.routes.post = expressServer.routes.post.filter (route) -> route.path isnt '/turnOffInstallationWizard'
			expressServer.routes.get = expressServer.routes.get.filter (route) -> route.path isnt '*'

		addProjectBindings = () =>
			@logger.info 'adding project bindings'

			expressServer.get '/', @handlers.indexHandler.handleRequest
			expressServer.get '/index', @handlers.indexHandler.handleRequest
			expressServer.get '/index.html', @handlers.indexHandler.handleRequest
			expressServer.get '/login', @handlers.indexHandler.handleRequest
			expressServer.get '/account', @handlers.indexHandler.handleRequest
			expressServer.get '/create/account', @handlers.indexHandler.handleRequest
			expressServer.get '/resetPassword', @handlers.indexHandler.handleRequest
			expressServer.get '/repository/:repositoryId', @handlers.indexHandler.handleRequest
			expressServer.get '/dashboard', @handlers.indexHandler.handleRequest
			expressServer.get '/analytics', @handlers.indexHandler.handleRequest
			expressServer.get '/admin', @handlers.indexHandler.handleRequest
			expressServer.get '/unexpectedError', @handlers.unexpectedErrorHandler.handleRequest
			expressServer.get '/invalidPermissions', @handlers.invalidPermissionsHandler.handleRequest

			expressServer.get '/ping', @_handlePing
			expressServer.post '/extendCookieExpiration', @_handleExtendCookieExpiration
			expressServer.post '/extendOAuthCookieExpiration', @_handleOAuthExtendCookieExpiration
			expressServer.get '/verifyAccount', @_handleVerifyEmail
			expressServer.get '/google/oAuthToken', @_handleSetGoogleOAuthToken
			expressServer.get '/gitHub/oAuthToken', @_handleSetGitHubOAuthToken
			expressServer.get '/gitHubEnterprise/authenticated', @_handleGitHubEnterpriseOAuthAuthenticated
			expressServer.post '/gitHub/verifyChange', @_handleGitHubHook
			
			@apiServer.addRoutes expressServer
			expressServer.get '*', @staticServer.handleRequest

		configureRoutes = () =>
			@modelConnection.rpcConnection.systemSettings.read.is_deployment_initialized (error, initialized) =>
				if error? then @logger.error error
				else
					clearTimeout configureRoutesFailedTimeoutId

					if initialized then addProjectBindings()
					else addInstallationWizardBindings()

					server = http.createServer expressServer
					server.listen @configurationParams.http.port

					@resourceConnection.start server

					@logger.info 'server started on ' + @configurationParams.http.port
					console.log "SERVER STARTED on port #{@configurationParams.http.port}".bold.magenta

		@logger.info 'starting server...'
		console.log "starting server...".magenta

		expressServer = express()
		
		@_configure expressServer
		@apiServer.addMiddleware expressServer

		# If model server isn't running, the exchanges won't be initialized.
		# If configureRoutes() doesn't return in a reasonable time, kill the webserver.
		configureRoutes()
		configureRoutesFailedTimeoutId = setTimeout (() =>
			throw 'Unable to determine if deployment is initialized'
		), 10000


	_configure: (expressServer) =>
		if process.env.NODE_ENV is 'production'
			console.log 'WARNING:'.bold.yellow + ' assuming webserver is behind a ssl terminator'.bold.cyan

		# ORDER IS IMPORTANT HERE!!!!
		expressServer.use express.favicon 'front/favicon.ico'
		expressServer.use express.cookieParser()
		expressServer.use express.query()

		expressServer.use (req, res, next) ->
			data = ''
			req.setEncoding 'utf8'
			req.on 'data', (chunk) ->
				data += chunk
			req.on 'end', () ->
				req.rawBody = data
			next()

		expressServer.use express.bodyParser()
		expressServer.use express.session
			secret: 'e0140cbb6dee1e7ceea9ca2219081c95b8e14a14'
			key: @cookieName
			cookie:
				path: '/'
				httpOnly: true
				secure: true if process.env.NODE_ENV is 'production'
			store: @stores.sessionStore
			proxy: true if process.env.NODE_ENV is 'production'
		expressServer.use csrf()
		expressServer.use gzip()


		expressServer.enable 'trust proxy' if process.env.NODE_ENV is 'production'

		expressServer.set 'view engine', 'ejs'
		expressServer.set 'views', @configurationParams.staticFiles.rootDirectory + '/roots'
		expressServer.locals.layout = false


	_handlePing: (request, response) =>
		response.send 'ok'


	_handleExtendCookieExpiration: (request, response) =>
		if not request.session.userId?
			@logger.warn 'Tried to extend cookie expiration for user not logged in'
			response.send 403, 'User not logged in'
		else
			@logger.info 'Extending cookie expiration for: ' + request.session.userId
			request.session.cookie.maxAge = 2592000000 # one month
			request.session.cookieExpirationIncreased ?= 0 
			request.session.cookieExpirationIncreased++
			response.send 'ok'


	_handleOAuthExtendCookieExpiration: (request, response) =>
		if request.session.userId?
			@logger.warn 'Tried to extend cookie expiration for user already logged in'
			response.send 403, 'User already logged in'
		else
			@logger.info 'Extending cookie expiration for oauth login'
			request.session.oAuthExtendCookie = true
			response.send 'ok'


	_isEmailAllowed: (userEmail, callback) =>
		@modelConnection.rpcConnection.systemSettings.read.get_allowed_email_domains 1, (error, emailDomains) =>
			if error? then callback error
			else if userEmail.indexOf('@') is -1 then callback 'Invaild email'
			else 
				userEmailDomain = userEmail.substring userEmail.indexOf('@') + 1
				callback null, (emailDomains.length is 0) or (userEmailDomain in emailDomains)


	_handleVerifyEmail: (request, response) =>
		token = request.query?.token

		if not token? then response.send 400, 'No token provided'
		else if request.session.userId?
			@logger.warn 'Tried to create account when user already logged in'
			response.send 403, 'Already logged in'
		else
			@stores.createAccountStore.getAccount token, (error, account) =>
				if error? then response.send 500, 'Error while verifying email address'
				else if not account? then response.send 500, 'No matching account information found'
				else 
					@_isEmailAllowed account.email, (error, emailAllowed) =>
						if error? then response.send 500, 'Error while verifying email address'
						else if not emailAllowed
							response.send "Email address #{account.email} is not allowed. Contact your admin if you feel this is in error"
							@stores.createAccountStore.removeAccount token
						else
							@modelConnection.rpcConnection.users.create.create_user account.email, account.firstName, account.lastName, 
								account.passwordHash, account.passwordSalt, account.isAdmin, (error, userId) =>
									if error?.type is 'UserAlreadyExistsError'
										@stores.createAccountStore.removeAccount token
										response.send 403, 'User already exists'
									else if error?
										response.send 500, 'Error while verifying email address'
									else
										@stores.createAccountStore.removeAccount token
										request.session.userId = userId
										response.redirect '/'


	_handleSetGoogleOAuthToken: (req, res) =>
		getEmailFromOAuthToken = (callback) =>
			requestParams =
				uri: 'https://www.googleapis.com/oauth2/v2/userinfo'
				qs:
					access_token: oauthToken
				json: true
			request.get requestParams, (error, response, body) =>
				if error? then callback error
				else if response.statusCode isnt 200 then callback response.statusCode
				else callback null, body

		handleLogin = () =>
			getEmailFromOAuthToken (error, userInfo) =>
				if error?
					@logger.warn error
					res.redirect '/login?googleLoginError=Unable to handle Google OAuth'
				else if not userInfo.email? and not userInfo.verified_email
					@logger.info 'No email or email not verified'
					res.redirect '/login?googleLoginError=Invalid email address'
				else
					await
						@modelConnection.rpcConnection.systemSettings.read.get_allowed_connection_types 1, defer connectionTypesError, connectionTypes
						@modelConnection.rpcConnection.users.read.get_user userInfo.email, defer userError, user

					if connectionTypesError?
						@logger.warn connectionTypesError
						res.redirect '/login?googleLoginError=Error while loggin in'
					else if not ('google' in connectionTypes)
						@logger.warn 'Tried to connect using Google OAuth when not an allowed connection type'
						res.redirect '/login?googleLoginError=Not allowed to login using Google OAuth'
					else if userError?
						@logger.info userError
						res.redirect '/login?googleLoginError=No matching email address for ' + userInfo.email
					else
						req.session.userId = user.id
						if req.session.oAuthExtendCookie
							req.session.cookie.maxAge = 2592000000 # one month
							req.session.cookieExpirationIncreased ?= 0 
							req.session.cookieExpirationIncreased++
							delete req.session.oAuthExtendCookie
						res.redirect '/'

		handleCreateAccount = () =>
			getEmailFromOAuthToken (error, userInfo) =>
				if error?
					@logger.warn error
					res.redirect '/create/account?googleCreateAccountError=Unable to handle Google OAuth'
				else if not userInfo.email? and not userInfo.verified_email
					@logger.info 'No email or email not verified'
					res.redirect '/create/account?googleCreateAccountError=Invalid email address'
				else if not userInfo.given_name? or not userInfo.family_name?
					@logger.info 'No name information'
					res.redirect '/create/account?googleCreateAccountError=Not enough user information to complete account'
				else
					await
						@modelConnection.rpcConnection.systemSettings.read.get_allowed_connection_types 1, defer connectionTypesError, connectionTypes
						@_isEmailAllowed userInfo.email, defer emailAllowedError, emailAllowed
						crypto.randomBytes 16, defer saltError, salt

					if connectionTypesError?
						@logger.warn connectionTypesError
						res.redirect '/create/account?googleCreateAccountError=Error while creating account'
					else if emailAllowedError?
						@logger.warn emailAllowedError
						res.redirect '/create/account?googleCreateAccountError=Error while creating account'
					else if saltError?
						@logger.warn saltError
						res.redirect '/create/account?googleCreateAccountError=Error while creating account'
					else if not ('google' in connectionTypes)
						@logger.warn 'Tried to connect using Google OAuth when not an allowed connection type'
						res.redirect '/create/account?googleCreateAccountError=Not allowed to create account using Google OAuth'
					else if not emailAllowed
						@logger.info 'Tried to create account with invaild email ' + userInfo.email
						res.redirect '/create/account?googleCreateAccountError=Email address ' + userInfo.email + ' is not allowed. Contact your admin if you feel this is in error'
					else
						@modelConnection.rpcConnection.users.create.create_user userInfo.email, userInfo.given_name, userInfo.family_name, 
							'/cyY3wu1VgzFhjxwCMY6+5emuoorhb/NciATN10ypZrlCKiOsjv4KaVGP9xFa2Obveg+G1ZwXgPxI+heN2y/vQ==', salt.toString('base64'), false, 
							(error, userId) =>
								if error?.type is 'UserAlreadyExistsError'
									res.redirect '/create/account?googleCreateAccountError=User already exists'
								else if error?
									res.redirect '/create/account?googleCreateAccountError=Error while creating account'
								else
									req.session.userId = userId
									if req.session.oAuthExtendCookie
										req.session.cookie.maxAge = 2592000000 # one month
										req.session.cookieExpirationIncreased ?= 0 
										req.session.cookieExpirationIncreased++
										delete req.session.oAuthExtendCookie
									res.redirect '/'

		oauthToken = req.query?.token
		action = req.query?.action

		if not oauthToken? then res.send 400, 'No OAuth Token provided'
		else if not action? then res.send 400, 'No action provided'
		else
			if action is 'login' then handleLogin()
			else if action is 'createAccount' then handleCreateAccount()
			else res.send 500, 'Unexpceted action type: ' + action


	_handleSetGitHubOAuthToken: (request, response) =>
		userId = request.session.userId
		oauthToken = request.query?.token
		action = request.query?.action

		if not userId then response.send 500, 'Not logged in'
		else if not oauthToken? then response.send 400, 'No OAuth Token provided'
		else if not action? then response.send 400, 'No action provided'
		else
			@modelConnection.rpcConnection.users.update.change_github_oauth_token userId, oauthToken, (error) =>
				if error?
					@logger.warn error
					response.send 500, 'Error while trying to update oauth token'
				else
					@logger.info 'Successfully connected user to GitHub: ' + userId

					if action is 'sshKeys' then response.redirect '/account?view=sshKeys&importGitHubKeys'
					else if action is 'addRepository' then response.redirect '/admin?view=repositories&addGitHubRepository'
					else response.redirect '/'


	_handleGitHubEnterpriseOAuthAuthenticated: (req, res) =>
		getGitHubEnterpriseConfig = (callback) =>
			@modelConnection.rpcConnection.systemSettings.read.get_github_enterprise_config 1, (error, gitHubEnterpriseConfig) =>
				if error? then callback error
				else if gitHubEnterpriseConfig.url is '' then callback null, null
				else callback null,
					uri: gitHubEnterpriseConfig.url
					clientId: gitHubEnterpriseConfig.client_id
					clientSecret: gitHubEnterpriseConfig.client_secret

		userId = req.session.userId
		code = req.query?.code
		state = req.query?.state

		if not userId then res.send 500, 'Not logged in'
		else if not code? then res.send 500, 'Invalid code'
		else if not state? then res.send 500, 'Invalid state'
		else
			getGitHubEnterpriseConfig (error, gitHubEnterpriseConfig) =>
				requestParams =
					uri: "#{gitHubEnterpriseConfig.uri}/login/oauth/access_token"
					form:
						client_id: gitHubEnterpriseConfig.clientId
						client_secret: gitHubEnterpriseConfig.clientSecret
						code: code
					json: true
					strictSSL: false
				request.post requestParams, (error, response, body) =>
					if error?
						@logger.warn error
						res.send 500, 'Failed to complete OAuth'
					else if not body?.access_token?
						@logger.warn body
						@logger.warn 'No access token in body'
						res.send 500, 'Failed to complete OAuth'
					else
						@modelConnection.rpcConnection.users.update.change_github_oauth_token userId, body.access_token, (error) =>
							if error?
								@logger.warn error
								res.send 500, 'Error while trying to update oauth token'
							else
								@logger.info 'Successfully connected user to GitHub: ' + userId

								action = state
								if action is 'sshKeys' then res.redirect '/account?view=sshKeys&importGitHubKeys'
								else if action is 'addRepository' then res.redirect '/admin?view=repositories&addGitHubRepository'
								else res.redirect '/'


	_handleGitHubHook: (request, response) =>
		doesSecretMatch = (hookSecret, hash) =>
			shaHasher = crypto.createHmac 'sha1', hookSecret
			shaHasher.update request.rawBody
			expectedHash = shaHasher.digest 'hex'
			return hash is expectedHash

		@logger.info 'Received call from GitHub'

		hookData = null
		if request.headers['content-type'] is 'application/json'
			hookData = request.body
		else if request.headers['content-type'] is 'application/x-www-form-urlencoded'
			hookData = JSON.parse(request.body.payload)
		else
			@logger.warn 'Unsupported content-type used with GitHub hook'
			response.send 'Unsupported content-type'
			return

		repositoryOwner = null
		repositoryName = null
		ref = null
		beforeSha = null
		afterSha = null
		branchName = null

		if hookData.pull_request?
			if hookData?.pull_request?.state is 'closed'
				@logger.info 'Ignoring closed pull request'
				response.send 'ok'
				return

			repositoryOwner = hookData?.pull_request?.base?.repo?.owner?.login
			repositoryName = hookData?.pull_request?.base?.repo?.name
			ref = hookData?.pull_request?.base?.ref
			beforeSha = hookData?.pull_request?.base?.sha
			afterSha = hookData?.pull_request?.head?.sha
			# branchName = if ref? then ref.substring(ref.lastIndexOf('/') + 1) else null
			if ref?
				refsIndex = ref.indexOf('refs/heads/')
				branchName = if refsIndex is 0 then ref.substring('refs/heads/'.length) else ref
		else
			repositoryOwner = hookData?.repository?.owner?.name
			repositoryName = hookData?.repository?.name
			ref = hookData?.ref
			beforeSha = hookData?.before
			afterSha = hookData?.after
			# branchName = if ref? then ref.substring(ref.lastIndexOf('/') + 1) else null
			if ref?
				refsIndex = ref.indexOf('refs/heads/')
				branchName = if refsIndex is 0 then ref.substring('refs/heads/'.length) else ref

		if not repositoryOwner?
			@logger.warn 'No repository owner provided'
			response.send 400, 'No repository owner provided'
		else if not repositoryName?
			@logger.warn 'No repository name provided'
			response.send 400, 'No repository name provided'
		else if not branchName?
			@logger.warn 'No branch provided'
			response.send 400, 'No branch provided'
		else if not beforeSha?
			@logger.warn 'No before sha provided'
			response.send 400, 'No before sha provided'
		else if not afterSha?
			@logger.warn 'No after sha provided'
			response.send 400, 'No after sha provided'
		else
			@modelConnection.rpcConnection.repositories.read.get_github_repo 1, repositoryOwner, repositoryName, (error, repository) =>
				if error?
					@logger.warn error
					response.send 500, 'Error finding associated repository'
				else if request.headers['content-type'] is 'application/x-www-form-urlencoded' and 
					not doesSecretMatch repository.github.hook_secret, request.headers['x-hub-signature']?.substring 5
						@logger.warn 'Invalid signature'
						response.send 403, 'Invalid signature'
				else
					@modelConnection.rpcConnection.changes.create.create_github_commit_and_change 3, repositoryOwner, repositoryName, beforeSha, afterSha, branchName, (error) =>
						if error?
							@logger.warn error
							response.send 500, 'Error while creating GitHub commit and change'
						else
							@logger.info 'Successfully created GitHub commit and change'
							response.send 'ok'
