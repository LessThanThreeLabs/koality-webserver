fs = require 'fs'
assert = require 'assert'

RequestHandler = require './requestHandler'
FilesCacher = require './cache/filesCacher'


exports.create = (configurationParams, stores, modelRpcConnection, filesSuffix, logger) ->
	filesCacher = FilesCacher.create 'unexpected error', configurationParams, 'front/roots/unexpectedError.json', filesSuffix, logger
	return new UnexpectedErrorHandler configurationParams, stores, modelRpcConnection, filesCacher, filesSuffix, logger


class UnexpectedErrorHandler extends RequestHandler
	handleRequest: (request, response) =>
		response.render 'roots/unexpectedError'
