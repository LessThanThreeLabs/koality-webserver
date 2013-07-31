window.AccountSshKeys = ['$scope', '$location', 'rpc', 'events', 'initialState', 'notification', ($scope, $location, rpc, events, initialState, notification) ->
	$scope.orderByPredicate = 'alias'
	$scope.orderByReverse = false

	$scope.waitingOnGitHubImportRequest = false

	$scope.addKey =
		drawerOpen: false

	getKeys = () ->
		rpc 'users', 'read', 'getSshKeys', null, (error, keys) ->
			$scope.keys = keys

	handleAddedKey = (data) ->
		$scope.keys.push data

	handleRemovedKey = (data) ->
		keyToRemoveIndex = (index for key, index in $scope.keys when key.id is data.id)[0]
		$scope.keys.splice keyToRemoveIndex, 1 if keyToRemoveIndex?

	addKeyEvents = events('users', 'ssh pubkey added', initialState.user.id).setCallback(handleAddedKey).subscribe()
	removeKeyEvents = events('users', 'ssh pubkey removed', initialState.user.id).setCallback(handleRemovedKey).subscribe()
	$scope.$on '$destroy', addKeyEvents.unsubscribe
	$scope.$on '$destroy', removeKeyEvents.unsubscribe

	getKeys()

	$scope.removeKey = (key) ->
		rpc 'users', 'update', 'removeSshKey', id: key.id

	$scope.submitKey = () ->
		rpc 'users', 'update', 'addSshKey', $scope.addKey, (error) ->
			if error? then notification.error error
			else 
				notification.success 'Added SSH key: ' + $scope.addKey.alias
				$scope.clearAddKey()

	$scope.clearAddKey = () ->
		$scope.addKey =
			alias: ''
			key: ''
			drawerOpen: false

	$scope.importFromGitHub = () ->
		return if $scope.waitingOnGitHubImportRequest
		$scope.waitingOnGitHubImportRequest = true

		rpc 'users', 'update', 'addGitHubSshKeys', null, (error) ->
			$scope.waitingOnGitHubImportRequest = false

			if error isnt 'Key is already in use'
				# window.location.href = "http://127.0.0.1:1080/github/authenticate?url=#{$location.protocol()}://#{$location.host()}"
				window.location.href = "http://127.0.0.1:1081/github/authenticate?url=#{$location.protocol()}://#{$location.host()}:1080"
]