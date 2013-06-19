assert = require 'assert'

Emailer = require './emailer'


exports.create = (configurationParams, emailSender, domainRetriever) ->
	return new LoggerEmailer configurationParams, emailSender, domainRetriever


class LoggerEmailer extends Emailer
	send: (body, callback) =>
		@getDomain (error, domain) =>
			if error? then callback error
			else
				fromEmail = "#{@configurationParams.from.name} <#{@configurationParams.from.email}@#{domain}>"
				toEmail = @configurationParams.to.email
				subject = 'Logs'

				if process.env.NODE_ENV is 'production'
					@emailSender.sendText fromEmail, toEmail, subject, body, callback
				else
					console.log 'Not sending logger email while in development mode'
