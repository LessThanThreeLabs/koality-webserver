'use strict'

window.Login = ['$scope', 'rpc', 'cookieExtender', 'notification', ($scope, rpc, cookieExtender, notification) ->
	$scope.account = {}

	redirectToHome = () ->
		# this will force a refresh, rather than do html5 pushstate
		window.location.href = '/'

	$scope.login = () ->
		rpc 'users', 'update', 'login', $scope.account, (error, result) ->
			if error?
				$scope.account.password = ''
				notification.error error
			else
				if $scope.account.rememberMe is 'yes'
					cookieExtender.extendCookie (error) ->
						console.error error if error?
						redirectToHome()
				else
					redirectToHome()
]
