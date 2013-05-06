fs = require 'fs'
assert = require 'assert'

FilesCacher = require 'koality-files-cacher'
RequestHandler = require './requestHandler'


exports.create = (configurationParams, stores, modelRpcConnection, fileSuffix, logger) ->
	filesCacher = FilesCacher.create 'invalid permissions', configurationParams.staticFiles.rootDirectory, 'front/roots/invalidPermissions.json', fileSuffix, logger
	return new InvalidPermissionsHandler configurationParams, stores, modelRpcConnection, filesCacher, fileSuffix, logger


class InvalidPermissionsHandler extends RequestHandler
	handleRequest: (request, response) =>
		response.render 'roots/invalidPermissions'
