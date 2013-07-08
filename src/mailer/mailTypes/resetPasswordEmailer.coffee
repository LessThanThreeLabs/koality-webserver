assert = require 'assert'

Emailer = require './emailer'


exports.create = (configurationParams, emailSender, domainRetriever) ->
	return new ResetPasswordEmailer configurationParams, emailSender, domainRetriever


class ResetPasswordEmailer extends Emailer
	send: (toEmail, newPassword, callback) =>
		assert.ok callback?
		
		@getDomain (error, domain) =>
			if error? then callback error
			else
				payload =
					from: "#{@configurationParams.from.name} <#{@configurationParams.from.email}@#{domain}>"
					to: toEmail
					subject: 'Your new Koality password!'
					text: "Your new password is: #{newPassword}"
				
				@emailSender.sendMail payload, callback
