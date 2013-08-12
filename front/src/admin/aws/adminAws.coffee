'use strict'

window.AdminAws = ['$scope', 'rpc', 'notification', ($scope, rpc, notification) ->
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

	getAwsKeys()
	getAllowedInstanceSizes()
	getAllowedSecurityGroups()
	getInstanceSettings()
	getVerifierPoolSettings()

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
