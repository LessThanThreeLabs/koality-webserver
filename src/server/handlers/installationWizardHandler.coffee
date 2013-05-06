fs = require 'fs'
assert = require 'assert'

FilesCacher = require 'koality-files-cacher'
RequestHandler = require './requestHandler'


exports.create = (configurationParams, stores, modelRpcConnection, fileSuffix, logger) ->
	filesCacher = FilesCacher.create 'installation wizard', configurationParams.staticFiles.rootDirectory, 
		configurationParams.staticFiles.rootDirectory + '/roots/installationWizard.json', fileSuffix, logger
	return new InstallationWizardHandler configurationParams, stores, modelRpcConnection, filesCacher, fileSuffix, logger


class InstallationWizardHandler extends RequestHandler
	handleRequest: (request, response) =>
		# just in case there's a lingering session
		delete request.session.userId

		response.render 'installationWizard', 
			fileSuffix: @fileSuffix
			csrfToken: request.session.csrfToken
			cssFiles: @cssFilesString
			jsFiles: @jsFilesString
			