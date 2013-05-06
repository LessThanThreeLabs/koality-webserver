assert = require 'assert'
commander = require 'commander'


exports.create = () ->
	commandLineParser = new CommandLineParser
	commandLineParser.initialize()
	return commandLineParser


class CommandLineParser
	initialize: () =>
		commander.version('0.1.0')
			.option('--mode <development/production>', 'The mode to use')
			.option('--httpPort <n>', 'The http port to use', parseInt)
			.option('--configFile <file>', 'The configuration file to use')
			.parse(process.argv)


	getMode: () =>
		return commander.mode


	getHttpPort: () =>
		return commander.httpPort


	getConfigFile: () =>
		return commander.configFile
