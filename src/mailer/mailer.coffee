assert = require 'assert'
nodemailer = require 'nodemailer'

FeedbackEmailer = require './mailTypes/feedbackEmailer'
InviteUserEmailer = require './mailTypes/inviteUserEmailer'
ResetPasswordEmailer = require './mailTypes/resetPasswordEmailer'
InitialAdminEmailer = require './mailTypes/initialAdminEmailer'
LoggerEmailer = require './mailTypes/loggerEmailer'


exports.create = (configurationParams, domainRetriever) ->
	createEmailers = () ->
		feedback: FeedbackEmailer.create configurationParams.feedback, emailSender, domainRetriever
		inviteUser: InviteUserEmailer.create configurationParams.inviteUser, emailSender, domainRetriever
		resetPassword: ResetPasswordEmailer.create configurationParams.resetPassword, emailSender, domainRetriever
		initialAdmin: InitialAdminEmailer.create configurationParams.initialAdmin, emailSender, domainRetriever
		logger: LoggerEmailer.create configurationParams.logger, emailSender, domainRetriever
		
	smtpTransport = nodemailer.createTransport 'smtp',
		service: 'Mailgun'
		auth:
			user: 'postmaster@koalitycode.com'
			pass: '41acnysnz3s9'
		name: 'koality-webserver'

	emailSender =
		sendText: (from, to, subject, body, callback) ->
			payload =
				from: from
				to: to
				subject: subject
				text: body
			smtpTransport.sendMail payload, callback

	return createEmailers()
