fs = require 'fs'

Logger = require 'koality-logger'
ModelConnection = require 'koality-model-connection'
GitHubConnection = require 'koality-github-connection'

environment = require './environment'

CommandLineParser = require './commandLineParser'
DomainRetriever = require './domainRetriever'
Mailer = require './mailer/mailer'
Server = require './server/server'


startEverything = () ->
	commandLineParser = CommandLineParser.create()

	configurationParams = getConfiguration commandLineParser.getConfigFile(),
		commandLineParser.getMode(), commandLineParser.getHttpPort()

	environment.setEnvironmentMode configurationParams.mode

	domainRetriever = DomainRetriever.create()

	mailer = Mailer.create configurationParams.mailer, domainRetriever

	loggerPrintLevel = if process.env.NODE_ENV is 'production' then 'info' else 'warn'
	logger = Logger.create mailer.logger, 'error', loggerPrintLevel

	modelConnection = ModelConnection.create configurationParams.modelConnection.messageBroker,
		configurationParams.modelConnection.rpc,
		configurationParams.modelConnection.events,
		logger

	gitHubConnection = GitHubConnection.create configurationParams.gitHubConnection, modelConnection, logger

	process.on 'uncaughtException', (error) ->
		logger.error error, true
		setTimeout (() -> process.exit 1), 10000

	modelConnectionFailedTimeoutId = setTimeout (() =>
		throw 'Model Connection failed to connect'
	), 10000

	modelConnection.connect (error) ->
		if error? then logger.error error
		else
			clearTimeout modelConnectionFailedTimeoutId

			domainRetriever.setModelConnection modelConnection

			server = Server.create configurationParams.server, modelConnection, gitHubConnection, mailer, logger
			server.initialize (error) =>
				if error? then throw error
				else server.start()


getConfiguration = (configFileLocation = './config.json', mode, httpPort) ->
	config = JSON.parse(fs.readFileSync configFileLocation, 'ascii')
	if mode? then config.mode = mode
	if httpPort? then config.server.http.port = httpPort
	return Object.freeze config


startEverything()
