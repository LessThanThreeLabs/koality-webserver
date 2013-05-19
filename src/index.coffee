fs = require 'fs'

Logger = require 'koality-logger'
ModelConnection = require 'koality-model-connection'

environment = require './environment'

CommandLineParser = require './commandLineParser'
Mailer = require './mailer/mailer'
Server = require './server/server'


startEverything = () ->
	process.title = 'webserver'

	commandLineParser = CommandLineParser.create()

	configurationParams = getConfiguration commandLineParser.getConfigFile(),
		commandLineParser.getMode(), commandLineParser.getHttpPort()

	environment.setEnvironmentMode configurationParams.mode

	domainRetriever = getDomain: (callback) -> callback 'not connected to model server'

	mailer = Mailer.create configurationParams.mailer, domainRetriever

	logger = Logger.create mailer.logger, 'error'

	modelConnection = ModelConnection.create configurationParams.modelConnection.messageBroker,
		configurationParams.modelConnection.rpc,
		configurationParams.modelConnection.events,
		logger

	process.on 'uncaughtException', (error) ->
		logger.error error, true
		process.exit 1

	modelConnection.connect (error) ->
		if error? then throw error
		else
			domainRetriever.getDomain = (callback) ->
				modelConnection.rpcConnection.systemSettings.read.get_website_domain_name 1, callback

			server = Server.create configurationParams.server, modelConnection, mailer, logger
			server.initialize (error) =>
				if error? then throw error
				else server.start()


getConfiguration = (configFileLocation = './config.json', mode, httpPort) ->
	config = JSON.parse(fs.readFileSync configFileLocation, 'ascii')
	if mode? then config.mode = mode
	if httpPort? then config.server.http.port = httpPort
	return Object.freeze config


startEverything()
