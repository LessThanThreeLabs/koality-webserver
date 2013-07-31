window.AccountPassword = ['$scope', 'rpc', 'notification', ($scope, rpc, notification) ->
	$scope.password = {}

	$scope.submit = () ->
		console.log $scope.password
		if $scope.password.new isnt $scope.password.confirm
			notification.error 'Invalid password confirmation. Please check that you correctly confirmed your new password'
		else
			rpc 'users', 'update', 'changePassword', $scope.password, (error) ->
				if error? then notification.error error
				else notification.success 'Updated account password'
]
