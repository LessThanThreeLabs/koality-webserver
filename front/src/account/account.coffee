'use strict'

window.Account = ['$scope', '$location', '$routeParams', ($scope, $location, $routeParams) ->
	$scope.view = $routeParams.view ? 'basic'

	$scope.selectView = (view) ->
		$scope.view = view

	$scope.$watch 'view', () ->
		$location.search 'view', $scope.view
]

# window.AccountGitHub = ['$scope', '$location', 'rpc', 'notification', ($scope, $location, rpc, notification) ->
# 	getIsConnected = () ->
# 		rpc 'users', 'read', 'isConnectedToGitHub', null, (error, connected) ->
# 			if error? then notification.error error
# 			else $scope.connected = connected

# 	$scope.connect = () ->
# 		# window.location.href = "http://127.0.0.1:1080/github/authenticate?url=#{$location.protocol()}://#{$location.host()}"
# 		window.location.href = "http://127.0.0.1:1081/github/authenticate?url=#{$location.protocol()}://#{$location.host()}:1080"

# 	$scope.disconnect = () ->
# 		rpc 'users', 'update', 'clearGitHubOAuthToken', null, (error) ->
# 			$scope.connected = false

# 	getIsConnected()
# ]
