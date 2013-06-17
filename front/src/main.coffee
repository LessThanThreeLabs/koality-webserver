'use strict'


window.Main = ['$scope', 'rpc', 'events', 'initialState', 'notification', ($scope, rpc, events, initialState, notification) ->
	repositories = []

	getRepositories = () ->
		rpc.makeRequest 'repositories', 'read', 'getRepositories', null, (error, repos) ->
			repositories = repos
			updateChangeFinishedListeners()

	createChangeFinishedHandler = (repository) ->
		return (data) ->
			if data.submitter.id is initialState.user.id
				message = "<a href='/repository/#{repository.id}?change=#{data.id}'>Change #{data.number}</a> #{data.aggregateStatus}"
				if data.aggregateStatus is 'passed' then notification.success message
				else if data.aggregateStatus is 'failed' then notification.error message
				else if data.aggregateStatus is 'skipped' then notification.warning message

	changeFinishedListeners = []
	updateChangeFinishedListeners = () ->
		changeFinishedListener.unsubscribe() for changeFinishedListener in changeFinishedListeners
		changeFinishedListeners = []

		return if not initialState.loggedIn

		for repository in repositories
			changeFinishedListener = events.listen('repositories', 'change finished', repository.id).setCallback(createChangeFinishedHandler(repository)).subscribe()
			changeFinishedListeners.push changeFinishedListener
	$scope.$on '$destroy', () -> changeFinishedListener.unsubscribe() for changeFinishedListener in changeFinishedListeners

	checkLicenseStatus = () ->
		rpc.makeRequest 'systemSettings', 'read', 'getLicenseInformation', null, (error, licenseInformation) ->
			billingUpdateUrl = 'https://koalitycode.com/account/payment'

			console.log licenseInformation

			if licenseInformation.licenseTrialExpirationTime?
				trialDaysRemaining = Math.floor ((licenseInformation.licenseTrialExpirationTime * 1000) - Date.now()) / (1000 * 60 * 60 * 24)

			if licenseInformation.licenseUnpaidExpirationTime?
				unpaidDaysRemaining = Math.floor ((licenseInformation.licenseUnpaidExpirationTime * 1000) - Date.now()) / (1000 * 60 * 60 * 24)

			if trialDaysRemaining?
				if trialDaysRemaining <= 0
					notification.error "There are 0 days left on your free trial. <a href=\"#{billingUpdateUrl}\">Upgrade now to continue using Koality.</a>", 0
				else
					message = "There are #{trialDaysRemaining} days left on your free trial. <a href=\"#{billingUpdateUrl}\">Upgrade now</a> to continue using Koality uninterrupted."
					if trialDaysRemaining <= 7
						notification.warning message
					else
						notification.success message
			else if unpaidDaysRemaining?
				if unpaidDaysRemaining <= 0
					notification.error "Your payment method has expired. <a href=\"#{billingUpdateUrl}\">Update your billing information.</a>", 0
				else if unpaidDaysRemaining <= 15
					notification.warning "Your payment method is about to expire. <a href=\"#{billingUpdateUrl}\">Update your billing information.</a>"
			else if not licenseInformation.active
				notification.error "Your license has been deactivated. <a href=\"http://heyyeyaaeyaaaeyaeyaa.com\">Generate a new license key.</a>", 0

	if initialState.loggedIn
		getRepositories()
		checkLicenseStatus()
]
