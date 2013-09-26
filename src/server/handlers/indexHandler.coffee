fs = require 'fs'
assert = require 'assert'

FilesCacher = require 'koality-files-cacher'
RequestHandler = require './requestHandler'


exports.create = (configurationParams, stores, modelRpcConnection, fileSuffix, logger) ->
	filesCacher = FilesCacher.create 'index', configurationParams.staticFiles.rootDirectory,
		configurationParams.staticFiles.rootDirectory + '/roots/index.json', logger
	return new IndexHandler configurationParams, stores, modelRpcConnection, filesCacher, fileSuffix, logger


class IndexHandler extends RequestHandler
	handleRequest: (request, response) =>
		@getTemplateValues request.session, (error, templateValues) =>
			if error?
				request.session.destroy()
				response.end 'internal server error'
			else 
				response.render 'index', templateValues


	getTemplateValues: (session, callback) =>
		@modelRpcConnection.systemSettings.read.get_allowed_connection_types 1, (error, connectionTypes) =>
			if error? then callback error
			else 
				if session.userId?
					@modelRpcConnection.users.read.get_user_from_id session.userId, (error, user) =>
						if error? then callback error
						else callback null, @_generateTemplateValues session, user, connectionTypes[0]
				else
					callback null, @_generateTemplateValues session, null, connectionTypes[0]


	_generateTemplateValues: (session, user={}, userConnectionType) =>
		fileSuffix: @fileSuffix
		csrfToken: session.csrfToken
		cssFiles: @cssFilesString
		jsFiles: @jsFilesString
		userId: session.userId
		isAdmin: user.admin	? false
		userConnectionType: userConnectionType
