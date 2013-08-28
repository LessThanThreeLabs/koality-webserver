'use strict'

window.AdminAws = ['$scope', 'rpc', 'events', 'notification', ($scope, rpc, events, notification) ->
	$scope.makingRequest = false

	getAwsKeys = () ->
		rpc 'systemSettings', 'read', 'getAwsKeys', null, (error, awsKeys) ->
			$scope.awsKeys = awsKeys

	getAllowedInstanceSizes = () ->
		rpc 'systemSettings', 'read', 'getAwsAllowedInstanceSizes', null, (error, allowedInstanceSizes) ->
			$scope.allowedInstanceSizes = allowedInstanceSizes

	getAllowedSecurityGroups = () ->
		rpc 'systemSettings', 'read', 'getAwsSecurityGroups', null, (error, securityGroups) ->
			$scope.allowedSecurityGroups = securityGroups

	getInstanceSettings = () ->
		rpc 'systemSettings', 'read', 'getAwsInstanceSettings', null, (error, instanceSettings) ->
			$scope.instanceSettings = instanceSettings

	getVerifierPoolSettings = () ->
		rpc 'systemSettings', 'read', 'getVerifierPoolSettings', null, (error, verifierPoolSettings) ->
			$scope.verifierPoolSettings = verifierPoolSettings

	handleAwsKeysUpdated = (data) ->
		$scope.awsKeys = data

	handleAwsInstanceSettingsUpdated = (data) ->
		$scope.instanceSettings = data

	handleVerifierPoolUpdated = (data) ->
		$scope.verifierPoolSettings = data

	getAwsKeys()
	getAllowedInstanceSizes()
	getAllowedSecurityGroups()
	getInstanceSettings()
	getVerifierPoolSettings()

	awsKeysUpdatedEvents = events('systemSettings', 'aws keys updated', null).setCallback(handleAwsKeysUpdated).subscribe()
	awsInstanceSettingsUpdatedEvents = events('systemSettings', 'aws instance settings updated', null).setCallback(handleAwsInstanceSettingsUpdated).subscribe()
	verifierPoolUpdatedEvents = events('systemSettings', 'verifier pool settings updated', null).setCallback(handleVerifierPoolUpdated).subscribe()
	$scope.$on '$destroy', awsKeysUpdatedEvents.unsubscribe
	$scope.$on '$destroy', awsInstanceSettingsUpdatedEvents.unsubscribe
	$scope.$on '$destroy', verifierPoolUpdatedEvents.unsubscribe

	$scope.submit = () ->
		return if $scope.makingRequest
		$scope.makingRequest = true

		await
			rpc 'systemSettings', 'update', 'setAwsKeys', $scope.awsKeys, defer awsKeysError
			rpc 'systemSettings', 'update', 'setAwsInstanceSettings', $scope.instanceSettings, defer instanceSettingsError
			rpc 'systemSettings', 'update', 'setVerifierPoolSettings', $scope.verifierPoolSettings, defer verifierPoolSettingsError

		$scope.makingRequest = false
		if awsKeysError then notification.error awsKeysError
		else if instanceSettingsError then notification.error instanceSettingsError
		else if verifierPoolSettingsError then notification.error verifierPoolSettingsError
		else notification.success 'Updated AWS information'
]
