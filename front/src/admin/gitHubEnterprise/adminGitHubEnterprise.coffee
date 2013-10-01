'use strict'

window.AdminGitHubEnterprise = ['$scope', 'rpc', 'events', 'notification', ($scope, rpc, events, notification) ->
	$scope.makingRequest = false

	getGitHubEnterpriseSettings = () ->
		rpc 'systemSettings', 'read', 'getGitHubEnterpriseSettings', null, (error, gitHubEnterpriseSettings) ->
			$scope.settings = gitHubEnterpriseSettings

	handleSettigsUpdated = (data) ->
		$scope.settings = data

	# getGitHubEnterpriseSettings()

	# settingsUpdatedEvents = events('systemSettings', 'github enterprise settings updated', null).setCallback(handleSettigsUpdated).subscribe()
	# $scope.$on '$destroy', settingsUpdatedEvents.unsubscribe

	$scope.submit = () ->
		return if $scope.makingRequest
		$scope.makingRequest = true

		rpc 'systemSettings', 'update', 'setGitHubEnterpriseSettings', $scope.settings, (error) =>
			$scope.makingRequest = false
			if error? then notification.error error
			else notification.success 'Updated GitHub Enterprise settings'
]
