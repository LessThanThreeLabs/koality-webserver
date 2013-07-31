window.AccountSshKeys = ['$scope', '$location', 'rpc', 'events', 'initialState', 'notification', ($scope, $location, rpc, events, initialState, notification) ->
	$scope.orderByPredicate = 'alias'
	$scope.orderByReverse = false

	$scope.waitingOnGitHubImportRequest = false

	$scope.addKey =
		drawerOpen: false

	getKeys = () ->
		rpc 'users', 'read', 'getSshKeys', null, (error, keys) ->
			$scope.keys = keys

	# addKey = () ->
	# 	requestParams = 
	# 		alias: $scope.addKey.alias
	# 		key: $scope.addKey.key
	# 	rpc 'users', 'update', 'addSshKey', requestParams, (error) ->
	# 		if error?
	# 			$scope.addKey.showError = true
	# 		else 
	# 			notification.success 'Added SSH key ' + $scope.addKey.alias
	# 			$scope.addKey.showError = false
	# 			$scope.addKey.modalVisible = false

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

	# $scope.removeKey = (key) ->
	# 	rpc 'users', 'update', 'removeSshKey', id: key.id

	# $scope.submitKey = () ->
	# 	addKey()

	$scope.importFromGitHub = () ->
		return if $scope.waitingOnGitHubImportRequest
		$scope.waitingOnGitHubImportRequest = true

		rpc 'users', 'update', 'addGitHubSshKeys', null, (error) ->
			$scope.waitingOnGitHubImportRequest = false

			if error
				# window.location.href = "http://127.0.0.1:1080/github/authenticate?url=#{$location.protocol()}://#{$location.host()}"
				window.location.href = "http://127.0.0.1:1081/github/authenticate?url=#{$location.protocol()}://#{$location.host()}:1080"
]