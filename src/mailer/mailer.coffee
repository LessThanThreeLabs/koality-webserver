assert = require 'assert'
nodemailer = require 'nodemailer'

FeedbackEmailer = require './mailTypes/feedbackEmailer'
VerifyEmailEmailer = require './mailTypes/verifyEmailEmailer'
ResetPasswordEmailer = require './mailTypes/resetPasswordEmailer'
InitialAdminEmailer = require './mailTypes/initialAdminEmailer'
LoggerEmailer = require './mailTypes/loggerEmailer'


exports.create = (configurationParams, domainRetriever) ->
	createEmailers = () ->
		feedback: FeedbackEmailer.create configurationParams.feedback, emailSender, domainRetriever
		verifyEmail: VerifyEmailEmailer.create configurationParams.verifyEmail, emailSender, domainRetriever
		resetPassword: ResetPasswordEmailer.create configurationParams.resetPassword, emailSender, domainRetriever
		initialAdmin: InitialAdminEmailer.create configurationParams.initialAdmin, emailSender, domainRetriever
		logger: LoggerEmailer.create configurationParams.logger, emailSender, domainRetriever
		
	emailSender = nodemailer.createTransport 'smtp',
		service: 'Mailgun'
		auth:
			user: configurationParams.mailgun.user
			pass: configurationParams.mailgun.password
		tls:
			ciphers: 'SSLv3'

	return createEmailers()
