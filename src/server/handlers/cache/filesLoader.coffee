fs = require 'fs'
assert = require 'assert'


exports.create = (rootDirectory, filesToLoadUri, filesSuffix) ->
	return new FilesLoader rootDirectory, filesToLoadUri, filesSuffix


class FilesLoader
	constructor: (@rootDirectory, @filesToLoadUri, @filesSuffix) ->
		assert.ok @rootDirectory? and typeof @rootDirectory is 'string'
		assert.ok @filesToLoadUri? and typeof @filesToLoadUri is 'string'
		assert.ok @filesSuffix? and typeof @filesSuffix is 'string'


	load: (callback) =>
		fs.readFile @filesToLoadUri, 'ascii', (error, filesToLoad) =>
			if error?
				callback error
			else
				files = @_createFiles JSON.parse filesToLoad
				@_loadFileContent files, callback


	_createFiles: (filesToLoad) =>
		files = {}

		for fileType, contentTypes of filesToLoad
			files[fileType] = {}

			for contentType, fileNames of contentTypes
				for fileName in fileNames
					fileNameWithSuffix = if @_shouldAddFileSuffix fileType then @_getFileNameWithSuffix fileName, fileType else fileName
					files[fileType][fileNameWithSuffix] = {}
					files[fileType][fileNameWithSuffix].contentType = contentType
					files[fileType][fileNameWithSuffix].location = @_getFileLocation fileName

		return files


	_loadFileContent: (files, callback) =>
		await
			for fileType of files
				for fileName, file of files[fileType]
					fs.readFile file.location, 'binary', defer file.error, file.plain

		combinedErrors = ''
		for fileType of files
			for fileName, file of files[fileType]
				if file.error?
					console.error file.error
				combinedErrors += file.error + ' ' if file.error?

		if combinedErrors isnt ''
			callback combinedErrors
		else
			callback null, files


	_getFileLocation: (fileName) =>
		return @rootDirectory + fileName


	_getFileNameWithSuffix: (fileName, fileType) =>
		lastPeriodIndex = fileName.lastIndexOf '.'
		return fileName.substr(0, lastPeriodIndex) + @filesSuffix + fileName.substr(lastPeriodIndex)


	_shouldAddFileSuffix: (fileType) =>
		return fileType isnt 'font'