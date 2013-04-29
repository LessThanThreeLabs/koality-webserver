fs = require 'fs'
assert = require 'assert'

FilesCacher = require 'koality-files-cacher'
RequestHandler = require './requestHandler'


exports.create = (configurationParams, stores, modelRpcConnection, filesSuffix, logger) ->
	filesCacher = FilesCacher.create 'index', configurationParams.staticFiles.rootDirectory, 'front/roots/index.json', filesSuffix, logger
	return new IndexHandler configurationParams, stores, modelRpcConnection, filesCacher, filesSuffix, logger


class IndexHandler extends RequestHandler
	handleRequest: (request, response) =>
		@getTemplateValues request.session, (error, templateValues) =>
			if error?
				request.session.destroy()
				response.end 'internal server error'
			else 
				response.render 'roots/index', templateValues


	getTemplateValues: (session, callback) =>
		if session.userId?
			@modelRpcConnection.users.read.get_user_from_id session.userId, (error, user) =>
				if error? then callback error
				else callback null, @_generateTemplateValues session, user
		else
			callback null, @_generateTemplateValues session, null


	_generateTemplateValues: (session, user={}) =>
		fileSuffix: @fileSuffix
		csrfToken: session.csrfToken
		cssFiles: @cssFilesString
		jsFiles: @jsFilesString
		userId: session.userId
		email: user.email
		firstName: user.first_name
		lastName: user.last_name
		isAdmin: user.admin	? false
