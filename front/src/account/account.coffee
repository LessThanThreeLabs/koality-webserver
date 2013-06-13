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
		rpc.makeRequest 'users', 'update', 'changeBasicInformation', $scope.account, (error) ->
			if error? then notification.error 'Unable to update account information'
			else notification.success 'Updated account information'
]


window.AccountPassword = ['$scope', 'rpc', 'notification', ($scope, rpc, notification) ->
	$scope.account = {}

	$scope.submit = () ->
		rpc.makeRequest 'users', 'update', 'changePassword', $scope.account, (error) ->
			if error? then notification.error error
			else notification.success 'Updated account password'
]


window.AccountSshKeys = ['$scope', 'rpc', 'events', 'initialState', 'notification', ($scope, rpc, events, initialState, notification) ->
	$scope.orderByPredicate = 'alias'
	$scope.orderByReverse = false

	$scope.addKey = {}
	$scope.addKey.modalVisible = false

	getKeys = () ->
		rpc.makeRequest 'users', 'read', 'getSshKeys', null, (error, keys) ->
			$scope.$apply () -> $scope.keys = keys

	addKey = () ->
		requestParams = 
			alias: $scope.addKey.alias
			key: $scope.addKey.key
		rpc.makeRequest 'users', 'update', 'addSshKey', requestParams, (error) ->
			if error?
				$scope.$apply () ->
					$scope.addKey.showError = true
			else 
				notification.success 'Added ssh key ' + $scope.addKey.alias
				$scope.$apply () ->
					$scope.addKey.showError = false
					$scope.addKey.modalVisible = false

	resetKeyData = () ->
		$scope.addKey.alias = null
		$scope.addKey.key = null
		
	handleAddedKeyUpdated = (data) -> $scope.$apply () ->
		$scope.keys.push data

	handleRemovedKeyUpdate = (data) -> $scope.$apply () ->
		keyToRemoveIndex = (index for key, index in $scope.keys when key.id is data.id)[0]
		$scope.keys.splice keyToRemoveIndex, 1 if keyToRemoveIndex?

	addKeyEvents = events.listen('users', 'ssh pubkey added', initialState.user.id).setCallback(handleAddedKeyUpdated).subscribe()
	removeKeyEvents = events.listen('users', 'ssh pubkey removed', initialState.user.id).setCallback(handleRemovedKeyUpdate).subscribe()
	$scope.$on '$destroy', addKeyEvents.unsubscribe
	$scope.$on '$destroy', removeKeyEvents.unsubscribe

	getKeys()

	$scope.removeKey = (key) ->
		rpc.makeRequest 'users', 'update', 'removeSshKey', id: key.id

	$scope.submitKey = () ->
		addKey()

	$scope.$watch 'addKey.modalVisible', (newValue, oldValue) ->
		resetKeyData() if not newValue
]
