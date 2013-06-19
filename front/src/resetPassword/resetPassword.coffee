'use strict'

window.ResetPassword = ['$scope', 'rpc', ($scope, rpc) ->
	$scope.account = {}
	
	$scope.resetPassword = () ->
		rpc 'users', 'update', 'resetPassword', $scope.account, (error) ->
			if error?
				$scope.showSuccess = false
				$scope.showError = true
			else 
				$scope.showSuccess = true
				$scope.showError = false
]
