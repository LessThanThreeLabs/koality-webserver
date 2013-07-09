assert = require 'assert'

Emailer = require './emailer'


exports.create = (configurationParams, emailSender, domainRetriever) ->
	return new FeedbackEmailer configurationParams, emailSender, domainRetriever


class FeedbackEmailer extends Emailer
	send: (user, feedback, userAgent, screen) =>
		@getDomain (error, domain) =>
			if error? then console.error error
			else 
				payload =
					from: "#{@configurationParams.from.name} <#{@configurationParams.from.email}@#{domain}>"
					to: @configurationParams.to.email
					subject: 'Feedback'
					text: "User: #{user.firstName} #{user.lastName} (#{user.email})\n\nFeedback: #{feedback}\n\nUser Agent: #{userAgent}\n\nScreen: #{screen.width} x #{screen.height}"
				
				@emailSender.sendMail payload, (error) ->
					console.error error if error?
