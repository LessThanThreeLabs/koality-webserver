'use strict'

window.Wizard = ['$scope', '$http', 'rpc', 'notification', ($scope, $http, rpc, notification) ->
	# $scope.stage = 'licenseKey'
	$scope.stage = 'complete'

	$scope.license = {}
	$scope.admin = {}
	$scope.website = {}
	$scope.aws = {}

	$scope.waitingOnRequest = false

	$scope.completeLicenseKey = () ->
		return if $scope.waitingOnRequest
		$scope.waitingOnRequest = true

		rpc.makeRequest 'systemSettings', 'update', 'validateLicenseKey', $scope.license, (error) ->
			$scope.$apply () ->
				$scope.waitingOnRequest = false
				if error? notification.error error
				else $scope.stage = 'admin'

	$scope.completeAdminInformation = () ->
		return if $scope.waitingOnRequest
		$scope.waitingOnRequest = true

		rpc.makeRequest 'users', 'create', 'validateInitialAdminUser', $scope.admin, (error) ->
			$scope.$apply () ->
				$scope.waitingOnRequest = false
				if error? notification.error error
				else $scope.stage = 'verifyAdmin'

	$scope.completeVerifyAdmin = () ->
		return if $scope.waitingOnRequest
		$scope.waitingOnRequest = true

		rpc.makeRequest 'users', 'create', 'validateInitialAdminToken', $scope.admin, (error) ->
			$scope.$apply () ->
				$scope.waitingOnRequest = false
				if error? then notification.error error
				else $scope.stage = 'website'

	$scope.completeWebsiteInformation = () ->
		return if $scope.waitingOnRequest
		$scope.waitingOnRequest = true

		rpc.makeRequest 'systemSettings', 'update', 'validateInitialWebsiteSettings', $scope.website, (error) ->
			$scope.$apply () ->
				$scope.waitingOnRequest = false
				if error? then notification.error error
				else $scope.stage = 'aws'

	$scope.completeAwsInformation = () ->
		return if $scope.waitingOnRequest
		$scope.waitingOnRequest = true

		requestParams =
			license: $scope.license
			admin: $scope.admin
			website: $scope.website
			aws: $scope.aws

		rpc.makeRequest 'systemSettings', 'update', 'setDeploymentInitialized', requestParams, (error) ->
			$scope.$apply () ->
				$scope.waitingOnRequest = false
				if error? then notification.error error
				else
					$http.post('/turnOffInstallationWizard').error (data, status, headers, config) ->
						notification.error 'Fatal: unable to start Koality service!'
					$scope.stage = 'invite'

	$scope.goToCreateRepository = () ->
		window.location.href = '/admin?view=repositories'

	$scope.goToKoality = () ->
		window.location.href = '/'
]
