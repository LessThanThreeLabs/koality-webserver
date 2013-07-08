assert = require 'assert'

Emailer = require './emailer'


exports.create = (configurationParams, emailSender, domainRetriever) ->
	return new LoggerEmailer configurationParams, emailSender, domainRetriever


class LoggerEmailer extends Emailer
	send: (body, callback) =>
		@getDomain (error, domain) =>
			if error? then callback error
			else
				payload =
					from: "#{@configurationParams.from.name} <#{@configurationParams.from.email}@#{domain}>"
					to: @configurationParams.to.email
					subject: 'Logs'
					text: body
				
				if process.env.NODE_ENV is 'production'
					@emailSender.sendMail payload, callback
				else
					console.log 'Not sending logger email while in development mode'
					callback()
