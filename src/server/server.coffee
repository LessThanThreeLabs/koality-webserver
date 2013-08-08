fs = require 'fs'
assert = require 'assert'
colors = require 'colors'
http = require 'http'
express = require 'express'
expressResource = require 'express-resource'  # required for koality-api-server
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


exports.create = (configurationParams, modelConnection, mailer, logger) ->
	stores =
		sessionStore: SessionStore.create configurationParams
		createAccountStore: CreateAccountStore.create configurationParams
	
	cookieName = 'koality.session.id'
	resourceConnection = ResourceConnection.create modelConnection, stores, cookieName, mailer, logger
	
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
		assert.ok @configurationParams?
		assert.ok @cookieName?
		assert.ok @modelConnection?
		assert.ok @resourceConnection?
		assert.ok @stores?
		assert.ok @handlers?
		assert.ok @staticServer?
		assert.ok @apiServer?
		assert.ok @logger?


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
			expressServer.get '/analytics', @handlers.indexHandler.handleRequest
			expressServer.get '/admin', @handlers.indexHandler.handleRequest
			expressServer.get '/unexpectedError', @handlers.unexpectedErrorHandler.handleRequest
			expressServer.get '/invalidPermissions', @handlers.invalidPermissionsHandler.handleRequest

			expressServer.get '/ping', @_handlePing
			expressServer.post '/extendCookieExpiration', @_handleExtendCookieExpiration
			expressServer.get '/github/oauth', @_handleSetGitHubOAuthToken
			
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
		if not request.session.userId?
			@logger.warn 'Tried to extend cookie expiration for user not logged in'
			response.send 403, 'User not logged in'
		else
			@logger.info 'Extending cookie expiration for: ' + request.session.userId
			request.session.cookie.maxAge = 2592000000 # one month
			request.session.cookieExpirationIncreased ?= 0 
			request.session.cookieExpirationIncreased++
			response.send 'ok'


	_handleSetGitHubOAuthToken: (request, response) =>
		userId = request.session.userId
		oauthToken = request.query?.token

		if not userId then response.send 500, 'Not logged in'
		else if not oauthToken? then response.send 400, 'No OAuth Token provided'
		else
			@modelConnection.rpcConnection.users.update.change_github_oauth_token userId, oauthToken, (error) =>
				if error?
					@logger.warn error
					response.send 500, 'Error while trying to update oauth token'
				else
					@logger.info 'Successfully connected user to GitHub: ' + userId
					response.redirect '/'
