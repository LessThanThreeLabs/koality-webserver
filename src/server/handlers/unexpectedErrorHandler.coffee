fs = require 'fs'
assert = require 'assert'

FilesCacher = require 'koality-files-cacher'
RequestHandler = require './requestHandler'


exports.create = (configurationParams, stores, modelRpcConnection, fileSuffix, logger) ->
	filesCacher = FilesCacher.create 'unexpected error', configurationParams.staticFiles.rootDirectory, 
		configurationParams.staticFiles.rootDirectory + '/roots/unexpectedError.json', logger
	return new UnexpectedErrorHandler configurationParams, stores, modelRpcConnection, filesCacher, fileSuffix, logger


class UnexpectedErrorHandler extends RequestHandler
	handleRequest: (request, response) =>
		response.render 'unexpectedError'
