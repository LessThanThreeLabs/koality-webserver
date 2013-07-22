'use strict'

window.Account = ['$scope', '$location', '$routeParams', 'initialState', ($scope, $location, $routeParams, initialState) ->
	$scope.name = initialState.user.firstName + ' ' + initialState.user.lastName
	$scope.currentView = $routeParams.view ? 'basic'

	$scope.menuOptionClick = (viewName) ->
		$scope.currentView = viewName

	$scope.$watch 'currentView', (newValue, oldValue) ->
		$location.search 'view', newValue
]


window.AccountBasic = ['$scope', 'initialState', 'rpc', 'notification', ($scope, initialState, rpc, notification) ->
	$scope.account =
		firstName: initialState.user.firstName
		lastName: initialState.user.lastName

	$scope.submit = () ->
		rpc 'users', 'update', 'changeBasicInformation', $scope.account, (error) ->
			if error? then notification.error 'Unable to update account information'
			else notification.success 'Updated account information'
]


window.AccountPassword = ['$scope', 'rpc', 'notification', ($scope, rpc, notification) ->
	$scope.account = {}

	$scope.submit = () ->
		rpc 'users', 'update', 'changePassword', $scope.account, (error) ->
			if error? then notification.error error
			else notification.success 'Updated account password'
]


window.AccountSshKeys = ['$scope', 'rpc', 'events', 'initialState', 'notification', ($scope, rpc, events, initialState, notification) ->
	$scope.orderByPredicate = 'alias'
	$scope.orderByReverse = false

	$scope.addKey = {}
	$scope.addKey.modalVisible = false

	getKeys = () ->
		rpc 'users', 'read', 'getSshKeys', null, (error, keys) ->
			$scope.keys = keys

	addKey = () ->
		requestParams = 
			alias: $scope.addKey.alias
			key: $scope.addKey.key
		rpc 'users', 'update', 'addSshKey', requestParams, (error) ->
			if error?
				$scope.addKey.showError = true
			else 
				notification.success 'Added SSH key ' + $scope.addKey.alias
				$scope.addKey.showError = false
				$scope.addKey.modalVisible = false

	resetModalValues = () ->
		$scope.addKey.showError = false
		$scope.addKey.alias = null
		$scope.addKey.key = null
		
	handleAddedKeyUpdated = (data) ->
		$scope.keys.push data

	handleRemovedKeyUpdate = (data) ->
		keyToRemoveIndex = (index for key, index in $scope.keys when key.id is data.id)[0]
		$scope.keys.splice keyToRemoveIndex, 1 if keyToRemoveIndex?

	addKeyEvents = events('users', 'ssh pubkey added', initialState.user.id).setCallback(handleAddedKeyUpdated).subscribe()
	removeKeyEvents = events('users', 'ssh pubkey removed', initialState.user.id).setCallback(handleRemovedKeyUpdate).subscribe()
	$scope.$on '$destroy', addKeyEvents.unsubscribe
	$scope.$on '$destroy', removeKeyEvents.unsubscribe

	getKeys()

	$scope.removeKey = (key) ->
		rpc 'users', 'update', 'removeSshKey', id: key.id

	$scope.submitKey = () ->
		addKey()

	$scope.addKeysFromGitHub = () ->
		rpc 'users', 'update', 'addGitHubSshKeys', null, (error) ->
			if error is 'NoSuchGitHubOAuthToken'
				notification.warning 'You must be connected to GitHub. <a href="/account?view=gitHub">Connect to GitHub</a>'

	$scope.$watch 'addKey.modalVisible', (newValue, oldValue) ->
		resetModalValues() if not newValue
]


window.AccountGitHub = ['$scope', '$location', 'rpc', 'notification', ($scope, $location, rpc, notification) ->
	getIsConnected = () ->
		rpc 'users', 'read', 'isConnectedToGitHub', null, (error, connected) ->
			if error? then notification.error error
			else $scope.connected = connected

	$scope.connect = () ->
		# window.location.href = "http://127.0.0.1:1080/github/authenticate?url=#{$location.protocol()}://#{$location.host()}"
		window.location.href = "http://127.0.0.1:1081/github/authenticate?url=#{$location.protocol()}://#{$location.host()}:1080"

	$scope.disconnect = () ->
		rpc 'users', 'update', 'clearGitHubOAuthToken', null, (error) ->
			$scope.connected = false

	getIsConnected()
]
