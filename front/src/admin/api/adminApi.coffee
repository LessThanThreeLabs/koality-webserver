'use strict'

window.AdminApi = ['$scope', 'rpc', 'notification', ($scope, rpc, notification) ->
	$scope.mustConfirmRegenerateKey = false
	$scope.makingRequest = false

	getApiKey = () ->
		rpc 'systemSettings', 'read', 'getAdminApiKey', null, (error, apiKey) ->
			$scope.apiKey = apiKey

	getDomainName = () ->
		rpc 'systemSettings', 'read', 'getWebsiteSettings', null, (error, websiteSettings) ->
			$scope.domainName = websiteSettings.domainName

	getApiKey()
	getDomainName()

	$scope.regenerateKey = () ->
		$scope.mustConfirmRegenerateKey = true

	$scope.confirmRegenerateKey = () ->
		return if $scope.makingRequest
		$scope.makingRequest = true

		rpc 'systemSettings', 'update', 'regenerateApiKey', null, (error, apiKey) ->
			$scope.makingRequest = false
			$scope.apiKey = apiKey
			$scope.mustConfirmRegenerateKey = false
			notification.success 'Successfully updated API key'

	$scope.cancelRegenerateKey = () ->
		$scope.mustConfirmRegenerateKey = false
]
