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
			expressServer.get '/google/oAuthToken', @_handleSetGoogleOAuthToken
			expressServer.get '/gitHub/oAuthToken', @_handleSetGitHubOAuthToken
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
		# if not request.session.userId?
		# 	@logger.warn 'Tried to extend cookie expiration for user not logged in'
		# 	response.send 403, 'User not logged in'
		# else
		# 	@logger.info 'Extending cookie expiration for: ' + request.session.userId
			request.session.cookie.maxAge = 2592000000 # one month
			request.session.cookieExpirationIncreased ?= 0 
			request.session.cookieExpirationIncreased++
			response.send 'ok'


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
					@modelConnection.rpcConnection.users.read.get_user userInfo.email, (error, user) =>
						if error?
							res.redirect '/login?googleLoginError=No matching email address for ' + userInfo.email
						else 
							req.session.userId = user.id
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
					crypto.randomBytes 16, (error, salt) =>
						if error
							@logger.warn error
							res.redirect '/create/account?googleCreateAccountError=Error while creating account'
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


	_handleGitHubHook: (request, response) =>
		# { host: 'staging.koalitycode.com',
		# accept: '*/*',
		# 'user-agent': 'GitHub Hookshot bbde025',
		# 'x-github-event': 'push',
		# 'x-github-delivery': 'c4b07f7c-1f17-11e3-968e-68e5dd676335',
		# 'content-type': 'application/json',
		# 'x-hub-signature': 'sha1=8bab5e1b10b8dc64b86c17a540e141a2e59835e5',
		# 'content-length': '3788',
		# 'x-forwarded-proto': 'https',
		# 'x-forwarded-for': '192.30.252.48',
		# connection: 'close' }

		doesSecretMatch = (hookSecret, hash) =>
			console.log hookSecret
			console.log hash

			shaHasher = crypto.createHash 'sha1'
			shaHasher.update hookSecret
			shaHasher.update request.body
			expectedHash = shaHasher.digest 'hex'

			console.log hash
			console.log expectedHash
			console.log hash is expectedHash

			return true

		@logger.info 'Received call from GitHub'

		hookData = request.body

		repositoryOwner = hookData?.repository?.owner?.name
		repositoryName = hookData?.repository?.name
		ref = hookData?.ref
		beforeSha = hookData?.before
		afterSha = hookData?.after
		branchName = if ref? then ref.substring(ref.lastIndexOf('/') + 1) else null

		if not repositoryOwner? then response.send 400, 'No repository owner provided'
		else if not repositoryName? then response.send 400, 'No repository name provided'
		else if not branchName? then response.send 400, 'No branch provided'
		else if not beforeSha? then response.send 400, 'No before sha provided'
		else if not afterSha? then response.send 400, 'No after sha provided'
		else
			@modelConnection.rpcConnection.repositories.read.get_github_repo 1, repositoryOwner, repositoryName, (error, repository) =>
				if error?
					@logger.warn error
					response.send 500, 'Error finding associated repository'
				else if not doesSecretMatch repository.github.hook_secret, request.headers['x-hub-signature']?.substring 4
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
