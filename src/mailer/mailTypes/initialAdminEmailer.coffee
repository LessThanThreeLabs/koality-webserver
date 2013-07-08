assert = require 'assert'

Emailer = require './emailer'


exports.create = (configurationParams, emailSender, domainRetriever) ->
	return new InitialAdminEmailer configurationParams, emailSender, domainRetriever


class InitialAdminEmailer extends Emailer
	send: (email, firstName, lastName, token, callback) =>
		assert.ok callback?
		
		@getDomain (error, domain) =>
			if error? then callback error
			else
				payload =
					from: "#{@configurationParams.from.name} <#{@configurationParams.from.email}@#{domain}>"
					to: "#{firstName} #{lastName} <#{email}>"
					subject: 'Koality admin token'
					text: "Hello #{firstName} #{lastName}, your admin token is: #{token}"
				
				@emailSender.sendMail payload, callback
