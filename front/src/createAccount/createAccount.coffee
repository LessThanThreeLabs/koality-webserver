'use strict'

window.CreateAccount = ['$scope', '$location', '$routeParams', '$timeout', 'rpc', 'notification', ($scope, $location, $routeParams, $timeout, rpc, notification) ->
	$scope.account = {}
	$scope.makingRequest = false

	if $routeParams.googleCreateAccountError
		googleCreateAccountError = $routeParams.googleCreateAccountError
		$location.search 'googleCreateAccountError', null
		$timeout (() -> notification.error googleCreateAccountError), 100

	# getEmailFromToken = () ->
	# 	rpc 'users', 'create', 'getEmailFromToken', token: $routeParams.token, (error, email) ->
	# 		$scope.account.email = email

	# $scope.account.token = $routeParams.token
	# getEmailFromToken()
	
	$scope.createAccount = () ->
		return if $scope.makingRequest
		$scope.makingRequest = true

		rpc 'users', 'create', 'createUser', $scope.account, (error, result) ->
			$scope.makingRequest = false
			if error then notification.error error
			else
				# this will force a refresh, rather than do html5 pushstate
				window.location.href = '/'


	$scope.googleCreateAccount = () ->
		return if $scope.makingRequest
		$scope.makingRequest = true

		rpc 'users', 'read', 'getGoogleCreateAccountRedirect', null, (error, redirectUri) ->
			$scope.makingRequest = false
			
			if error? then notification.error error
			else
				window.location.href = redirectUri
]
