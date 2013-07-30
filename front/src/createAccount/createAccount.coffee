'use strict'

window.CreateAccount = ['$scope', '$routeParams', 'rpc', 'notification', ($scope, $routeParams, rpc, notification) ->
	getEmailFromToken = () ->
		rpc 'users', 'create', 'getEmailFromToken', token: $routeParams.token, (error, email) ->
			$scope.account.email = email

	$scope.account = {}
	$scope.account.token = $routeParams.token
	getEmailFromToken()
	
	$scope.submit = () ->
		rpc 'users', 'create', 'createUser', $scope.account, (error, result) ->
			if error then notification.error error
			else
				# this will force a refresh, rather than do html5 pushstate
				window.location.href = '/'
]
