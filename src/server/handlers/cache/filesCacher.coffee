assert = require 'assert'
colors = require 'colors'

FilesLoader = require './filesLoader'
FilesMinifier = require './filesMinifier'
FilesCompressor = require './filesCompressor'


exports.create = (name, rootDirectory, filesToLoadUri, filesSuffix, logger) ->
	filesLoader = FilesLoader.create rootDirectory, filesToLoadUri, filesSuffix
	filesMinifier = FilesMinifier.create()
	filesCompressor = FilesCompressor.create()
	return new FilesCacher name, filesLoader, filesMinifier, filesCompressor


class FilesCacher
	_files: null

	constructor: (@name, @filesLoader, @filesMinifier, @filesCompressor) ->
		assert.ok @name? and typeof @name is 'string'
		assert.ok @filesLoader? and typeof @filesLoader is 'object'
		assert.ok @filesMinifier? and typeof @filesMinifier is 'object'
		assert.ok @filesCompressor? and typeof @filesCompressor is 'object'


	loadFiles: (callback) =>
		@filesLoader.load (error, files) =>
			console.log @name.cyan + ' - loaded files'.white
			if error?
				callback error
			else
				@_files = files
				@_minifyFiles callback


	_minifyFiles: (callback) =>
		if process.env.NODE_ENV is 'production'
			@filesMinifier.replaceWithMinifiedFiles @_files, (error) =>
				console.log @name.cyan + ' - minified files'.white
				if error?
					callback error
				else
					@_compressFiles callback
		else
			@_compressFiles callback


	_compressFiles: (callback) =>
		@filesCompressor.addCompressedFiles @_files, callback
		console.log @name.cyan + ' - compressed files'.white


	getFiles: () =>
		assert.ok @_files?
		return @_files
