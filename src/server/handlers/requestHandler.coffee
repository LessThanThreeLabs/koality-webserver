assert = require 'assert'


module.exports = class Resource
	constructor: (@configurationParams, @stores, @modelRpcConnection, @filesCacher, @fileSuffix, @logger) ->
		assert.ok @configurationParams? 
		assert.ok @stores?
		assert.ok @modelRpcConnection?
		assert.ok @filesCacher?
		assert.ok @fileSuffix?
		assert.ok @logger?


	initialize: (callback) =>
		@filesCacher.loadFiles (error) =>
			if error
				callback error
			else
				@loadResourceStrings()
				callback()


	handleRequest: (request, response) =>
		response.send 'response handler not written yet'


	getFiles: () =>
		assert.ok @filesCacher.getFiles()
		return @filesCacher.getFiles()


	loadResourceStrings: () =>
		@_createCssString()
		@_createJsString()


	_getFilenameWithSuffix: (filename, fileType) =>
		lastPeriodIndex = filename.lastIndexOf '.'
		if lastPeriodIndex is -1 then return filename 
		else return filename.substr(0, lastPeriodIndex) + @fileSuffix + filename.substr(lastPeriodIndex)


	_createCssString: () =>
		cssFiles = @getFiles().css
		if not cssFiles?
			@cssFilesString = ''
		else
			cssFilenames = Object.keys cssFiles
			formatedCssFiles = cssFilenames.map (cssFilename) =>
				filenameWithSuffix = @_getFilenameWithSuffix cssFilename
				return "<link rel='stylesheet' type='text/css' href='#{filenameWithSuffix}' />"
			@cssFilesString = formatedCssFiles.join '\n'


	_createJsString: () =>
		jsFiles = @getFiles().js
		if not jsFiles?
			@jsFilesString = ''
		else
			jsFilenames = Object.keys jsFiles
			formattedJsFiles = jsFilenames.map (jsFilename) =>
				filenameWithSuffix = @_getFilenameWithSuffix jsFilename
				return "<script src='#{filenameWithSuffix}'></script>"
			@jsFilesString = formattedJsFiles.join '\n'
