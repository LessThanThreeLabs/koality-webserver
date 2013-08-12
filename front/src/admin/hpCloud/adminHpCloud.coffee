'use strict'

window.AdminHpCloud = ['$scope', 'rpc', 'notification', ($scope, rpc, notification) ->
	$scope.makingRequest = false

	getHpCloudKeys = () ->
		rpc 'systemSettings', 'read', 'getHpCloudKeys', null, (error, hpCloudKeys) ->
			$scope.hpCloudKeys = hpCloudKeys

	getAllowedRegions = () ->
		rpc 'systemSettings', 'read', 'getHpCloudAllowedRegions', null, (error, allowedRegions) ->
			$scope.allowedRegions = allowedRegions

	getAllowedInstanceSizes = () ->
		rpc 'systemSettings', 'read', 'getHpCloudAllowedInstanceSizes', null, (error, allowedInstanceSizes) ->
			$scope.allowedInstanceSizes = allowedInstanceSizes

	getAllowedSecurityGroups = () ->
		rpc 'systemSettings', 'read', 'getHpCloudSecurityGroups', null, (error, securityGroups) ->
			$scope.allowedSecurityGroups = securityGroups

	getInstanceSettings = () ->
		rpc 'systemSettings', 'read', 'getHpCloudInstanceSettings', null, (error, instanceSettings) ->
			$scope.instanceSettings = instanceSettings

	getVerifierPoolSettings = () ->
		rpc 'systemSettings', 'read', 'getVerifierPoolSettings', null, (error, verifierPoolSettings) ->
			$scope.verifierPoolSettings = verifierPoolSettings

	getHpCloudKeys()
	getAllowedInstanceSizes()
	getAllowedRegions()
	getAllowedSecurityGroups()
	getInstanceSettings()
	getVerifierPoolSettings()

	$scope.submit = () ->
		return if $scope.makingRequest
		$scope.makingRequest = true

		await
			rpc 'systemSettings', 'update', 'setHpCloudKeys', $scope.hpCloudKeys, defer hpCloudKeysError
			rpc 'systemSettings', 'update', 'setHpCloudInstanceSettings', $scope.instanceSettings, defer instanceSettingsError
			rpc 'systemSettings', 'update', 'setVerifierPoolSettings', $scope.verifierPoolSettings, defer verifierPoolSettingsError

		$scope.makingRequest = false
		if hpCloudKeysError then notification.error hpCloudKeysError
		else if instanceSettingsError then notification.error instanceSettingsError
		else if verifierPoolSettingsError then notification.error verifierPoolSettingsError
		else notification.success 'Updated HP Cloud information'
]
