'use strict'

window.AdminAws = ['$scope', 'rpc', 'notification', ($scope, rpc, notification) ->
	getAwsKeys = () ->
		rpc 'systemSettings', 'read', 'getAwsKeys', null, (error, awsKeys) ->
			$scope.awsKeys = awsKeys

	getAllowedInstanceSizes = () ->
		rpc 'systemSettings', 'read', 'getAllowedInstanceSizes', null, (error, allowedInstanceSizes) ->
			$scope.allowedInstanceSizes = allowedInstanceSizes

	getInstanceSettings = () ->
		rpc 'systemSettings', 'read', 'getInstanceSettings', null, (error, instanceSettings) ->
			$scope.instanceSettings = instanceSettings

	getAwsKeys()
	getAllowedInstanceSizes()
	getInstanceSettings()

	$scope.submit = () ->
		await
			rpc 'systemSettings', 'update', 'setAwsKeys', $scope.awsKeys, defer awsKeysError
			rpc 'systemSettings', 'update', 'setInstanceSettings', $scope.instanceSettings, defer instanceSettingsError

		if awsKeysError then notification.error awsKeysError
		else if instanceSettingsError then notification.error instanceSettingsError
		else notification.success 'Updated aws information'
]
