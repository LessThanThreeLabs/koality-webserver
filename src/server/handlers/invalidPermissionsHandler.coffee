fs = require 'fs'
assert = require 'assert'

FilesCacher = require 'koality-files-cacher'
RequestHandler = require './requestHandler'


exports.create = (configurationParams, stores, modelRpcConnection, filesSuffix, logger) ->
	filesCacher = FilesCacher.create 'invalid permissions', configurationParams.staticFiles.rootDirectory, 'front/roots/invalidPermissions.json', filesSuffix, logger
	return new InvalidPermissionsHandler configurationParams, stores, modelRpcConnection, filesCacher, filesSuffix, logger


class InvalidPermissionsHandler extends RequestHandler
	handleRequest: (request, response) =>
		response.render 'roots/invalidPermissions'
