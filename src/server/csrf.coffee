crypto = require 'crypto'

module.exports = () ->
	return (request, response, next) ->
		if request.session?.csrfToken? then next()
		else
			crypto.pseudoRandomBytes 8, (keyError, keyBuffer) =>
				throw keyError if keyError?
				request.session?.csrfToken = keyBuffer.toString 'hex'
				next()
