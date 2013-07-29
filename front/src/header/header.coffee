'use strict'

window.Header = ['$scope', '$location', 'initialState', 'rpc', 'events', ($scope, $location, initialState, rpc, events) ->
	$scope.loggedIn = initialState.loggedIn
	$scope.isAdmin = initialState.user.isAdmin
	
	getRepositories = () ->
		return if not $scope.loggedIn

		rpc 'repositories', 'read', 'getRepositories', null, (error, repositories) ->
			$scope.repositories = repositories

	handleRepositoryAdded = (data) ->
		$scope.repositories.push data

	handleRepositoryRemoved = (data) ->
		repositoryToRemoveIndex = (index for repository, index in $scope.repositories when repository.id is data.id)[0]
		$scope.repositories.splice repositoryToRemoveIndex, 1 if repositoryToRemoveIndex?

	if $scope.loggedIn
		addRepositoryEvents = events('users', 'repository added', initialState.user.id).setCallback(handleRepositoryAdded).subscribe()
		removeRepositoryEvents = events('users', 'repository removed', initialState.user.id).setCallback(handleRepositoryRemoved).subscribe()
		$scope.$on '$destroy', addRepositoryEvents.unsubscribe
		$scope.$on '$destroy', removeRepositoryEvents.unsubscribe
	
	getRepositories()

	# $scope.submitFeedback = () ->
	# 	requestParams =
	# 		feedback: $scope.feedback.text
	# 		userAgent: navigator.userAgent
	# 		screen: window.screen
	# 	rpc 'users', 'update', 'submitFeedback', requestParams

	# 	$scope.feedback.showSuccess = true
	
	$scope.performLogout = () ->
		return if $scope.loggedIn

		rpc 'users', 'update', 'logout', null, (error) ->
			# this will force a refresh, rather than do html5 pushstate
			window.location.href = '/'

]
