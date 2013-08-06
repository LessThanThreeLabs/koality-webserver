'use strict'

window.AdminUpgrade = ['$scope', 'initialState', 'rpc', 'events', ($scope, initialState, rpc, events) ->
	$scope.upgrade = {}
	$scope.makingRequest = false

	getUpgradeStatus = () ->
		rpc 'systemSettings', 'read', 'getUpgradeStatus', null, (error, upgradeStatus) ->
			handleUpgradeStatus upgradeStatus

	handleUpgradeStatus = (upgradeStatus) ->
		lastUpgradeStatus = upgradeStatus.lastUpgradeStatus
		upgradeAvailable = upgradeStatus.upgradeAvailable ? false

		if lastUpgradeStatus is 'running'
			$scope.upgrade.message = 'An upgrade is currently in progress. You should expect the system to restart in a few minutes.'
			$scope.upgrade.upgradeAllowed = false
		else if lastUpgradeStatus is 'failed'
			$scope.upgrade.message = 'The last upgrade failed. Contact support if this happens again.'
			$scope.upgrade.upgradeAllowed = upgradeAvailable
		else if upgradeAvailable
			$scope.upgrade.message = 'An upgrade to Koality is available. Upgrading will shut down the server and may take several minutes before restarting.'
			$scope.upgrade.upgradeAllowed = true
		else
			$scope.upgrade.message = 'There are no upgrades available at this time.'
			$scope.upgrade.upgradeAllowed = false

	handleSystemSettingsUpdate = (data) ->
		if data.resource is 'deployment' and data.key is 'upgrade_status'
			handleUpgradeStatus lastUpgradeStatus: data.value

	changedSystemSetting = events('systemSettings', 'system setting updated', initialState.user.id).setCallback(handleSystemSettingsUpdate).subscribe()
	$scope.$on '$destroy', changedSystemSetting.unsubscribe

	getUpgradeStatus()

	$scope.performUpgrade = () ->
		return if $scope.makingRequest
		$scope.makingRequest = true

		$scope.upgrade.upgradeAllowed = false
		rpc 'systemSettings', 'update', 'upgradeDeployment', null, (error) ->
			$scope.makingRequest = false
]
