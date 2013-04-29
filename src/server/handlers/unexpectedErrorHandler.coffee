fs = require 'fs'
assert = require 'assert'

FilesCacher = require 'koality-files-cacher'
RequestHandler = require './requestHandler'


exports.create = (configurationParams, stores, modelRpcConnection, filesSuffix, logger) ->
	filesCacher = FilesCacher.create 'unexpected error', configurationParams.staticFiles.rootDirectory, 'front/roots/unexpectedError.json', filesSuffix, logger
	return new UnexpectedErrorHandler configurationParams, stores, modelRpcConnection, filesCacher, filesSuffix, logger


class UnexpectedErrorHandler extends RequestHandler
	handleRequest: (request, response) =>
		response.render 'roots/unexpectedError'
