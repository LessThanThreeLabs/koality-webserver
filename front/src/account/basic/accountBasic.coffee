window.AccountBasic = ['$scope', 'initialState', 'rpc', 'notification', ($scope, initialState, rpc, notification) ->
	$scope.account =
		email: initialState.user.email

	getName = () ->
		rpc 'users', 'read', 'getBasicInformation', null, (error, basicInformation) ->
			if error? then notification.error error
			else if not $scope.account.firstName? and not $scope.account.lastName?
				$.extend true, $scope.account, basicInformation

	getName()

	$scope.submit = () ->
		rpc 'users', 'update', 'changeBasicInformation', $scope.account, (error) ->
			if error? then notification.error 'Unable to update account information'
			else notification.success 'Updated account information'
]
