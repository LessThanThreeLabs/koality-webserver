window.AccountPassword = ['$scope', 'rpc', 'notification', ($scope, rpc, notification) ->
	$scope.makingRequest = false
	$scope.password = {}

	$scope.submit = () ->
		if $scope.password.new isnt $scope.password.confirm
			notification.error 'Invalid password confirmation. Please check that you correctly confirmed your new password'
		else
			return if $scope.makingRequest
			$scope.makingRequest = true

			rpc 'users', 'update', 'changePassword', $scope.password, (error) ->
				$scope.makingRequest = false
				if error? then notification.error error
				else notification.success 'Updated account password'
]
