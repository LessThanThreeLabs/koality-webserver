fs = require 'fs'
assert = require 'assert'
crypto = require 'crypto'


exports.create = () ->
	return new FilesMinifier()


class FilesMinifier
	replaceWithMinifiedFiles: (files, callback) =>
		crypto.randomBytes 8, (error, buffer) =>
			if error?
				callback error
			else
				@randomPrefix = buffer.toString 'hex'
				@_replaceJs files if files.js?
				@_replaceCss files if files.css?
				callback()


	_replaceJs: (files) =>
		minifiedJsCode = @_concatenateFileContents files.js

		minifiedJsFile =
			plain: minifiedJsCode
			contentType: 'application/javascript'

		files.js = {}
		files.js["/js/#{@randomPrefix}_minified.js"] = minifiedJsFile


	_replaceCss: (files) =>
		minifiedCssCode = @_concatenateFileContents files.css

		minifiedCssFile =
			plain: minifiedCssCode
			contentType: 'text/css'

		files.css = {}
		files.css["/css/#{@randomPrefix}_minified.css"] = minifiedCssFile


	_concatenateFileContents: (files) =>
		textToConcatenate = []
		for fileName, file of files
			textToConcatenate.push file.plain

		return textToConcatenate.join '\n'
