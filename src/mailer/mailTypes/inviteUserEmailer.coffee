assert = require 'assert'

Emailer = require './emailer'


exports.create = (configurationParams, emailSender, domainRetriever) ->
	return new InviteUserEmailer configurationParams, emailSender, domainRetriever


class InviteUserEmailer extends Emailer
	send: (toEmail, userToken, callback) =>
		assert.ok callback?
		
		@getDomain (error, domain) =>
			if error? then callback error
			else
				uri = 'https://' + domain + '/create/account?token=' + userToken
				payload =
					from: "#{@configurationParams.from.name} <#{@configurationParams.from.email}@#{domain}>"
					to: toEmail
					subject: 'Welcome to Koality!'
					text: "Click here to create your account: #{uri}"
				
				@emailSender.sendMail payload, callback
