assert = require 'assert'

Emailer = require './emailer'


exports.create = (configurationParams, emailSender, domainRetriever) ->
	return new VerifyEmailEmailer configurationParams, emailSender, domainRetriever


class VerifyEmailEmailer extends Emailer
	send: (email, key, callback) =>
		assert.ok typeof email is 'string'
		assert.ok typeof key is 'string'
		assert.ok typeof callback is 'function'
		
		@getDomain (error, domain) =>
			if error? then callback error
			else
				uri = null
				if process.env.NODE_ENV is 'production' then uri = "https://#{domain}/verifyAccount?token=#{key}"
				else uri = "http://127.0.0.1:1080/verifyAccount?token=#{key}"

				payload =
					from: "#{@configurationParams.from.name} <#{@configurationParams.from.email}@#{domain}>"
					to: email
					subject: 'Verify Your Email'
					text: "Click here to verify your email and continue to your account: #{uri}"
				
				@emailSender.sendMail payload, callback
