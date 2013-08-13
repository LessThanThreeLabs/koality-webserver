'use strict'

window.AccountSshKeys = ['$scope', '$location', '$routeParams', '$timeout', 'rpc', 'events', 'initialState', 'notification', ($scope, $location, $routeParams, $timeout, rpc, events, initialState, notification) ->
	$scope.orderByPredicate = 'alias'
	$scope.orderByReverse = false

	$scope.currentlyOpenDrawer = null
	$scope.waitingOnGitHubImportRequest = false

	$scope.addKey =
		makingRequest: false
		drawerOpen: false

	if $routeParams.importGitHubKeys
		$timeout (() -> 
			$scope.importFromGitHub()
			$location.search 'importGitHubKeys', null
		), 100

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

	$scope.toggleDrawer = (drawerName) ->
		if $scope.currentlyOpenDrawer is drawerName
			$scope.currentlyOpenDrawer = null
		else
			$scope.currentlyOpenDrawer = drawerName

	$scope.removeKey = (key) ->
		rpc 'users', 'update', 'removeSshKey', id: key.id

	$scope.submitKey = () ->
		return if $scope.addKey.makingRequest
		$scope.addKey.makingRequest = true

		rpc 'users', 'update', 'addSshKey', $scope.addKey, (error) ->
			$scope.addKey.makingRequest = false
			if error? then notification.error error
			else 
				notification.success 'Added SSH key: ' + $scope.addKey.alias
				$scope.clearAddKey()

	$scope.clearAddKey = () ->
		$scope.addKey.alias = ''
		$scope.addKey.key = ''
		$scope.currentlyOpenDrawer = null

	$scope.importFromGitHub = () ->
		return if $scope.waitingOnGitHubImportRequest
		$scope.waitingOnGitHubImportRequest = true

		rpc 'users', 'update', 'addGitHubSshKeys', null, (error) ->
			$scope.waitingOnGitHubImportRequest = false

			if error?
				if error isnt 'NoSuchGitHubOAuthToken' and error isnt 'InvalidGitHubOAuthToken' then notification.error error
				else
					# window.location.href = "http://127.0.0.1:1080/github/authenticate?url=#{$location.protocol()}://#{$location.host()}"
					window.location.href = "http://127.0.0.1:1081/github/authenticate?url=#{$location.protocol()}://#{$location.host()}:1080&action=sshKeys"
			else
				notification.success 'Added GitHub SSH Keys'
]
