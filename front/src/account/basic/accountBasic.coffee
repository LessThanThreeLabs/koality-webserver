'use strict'

window.AccountBasic = ['$scope', 'initialState', 'rpc', 'notification', ($scope, initialState, rpc, notification) ->
	$scope.makingRequest = false
	$scope.account =
		email: initialState.user.email
		firstName: null
		oldFirstName: null
		lastName: null
		oldLastName: null
		infoChanged: false

	getName = () ->
		rpc 'users', 'read', 'getBasicInformation', null, (error, basicInformation) ->
			if error? then notification.error error
			else if not $scope.account.firstName? and not $scope.account.lastName?
				$scope.account.firstName = basicInformation.firstName
				$scope.account.oldFirstName = basicInformation.firstName
				$scope.account.lastName = basicInformation.lastName
				$scope.account.oldLastName = basicInformation.lastName

	getName()

	$scope.submit = () ->
		return if $scope.makingRequest
		$scope.makingRequest = true

		# in case they change in the UI while waiting for request to come back
		firstName = $scope.account.firstName
		lastName = $scope.account.lastName

		rpc 'users', 'update', 'changeBasicInformation', $scope.account, (error) ->
			$scope.makingRequest = false
			if error? then notification.error 'Unable to update account information'
			else
				notification.success 'Updated account information'
				$scope.account.oldFirstName = firstName
				$scope.account.oldLastName = lastName
]
