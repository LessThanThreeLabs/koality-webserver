'use strict'

window.Header = ['$scope', '$location', 'initialState', 'rpc', 'events', 'notification', ($scope, $location, initialState, rpc, events, notification) ->
	$scope.loggedIn = initialState.loggedIn
	$scope.isAdmin = initialState.user.isAdmin
	$scope.feedback = open: false

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

	$scope.sendFeedback = () ->
		if not $scope.feedback.message or $scope.feedback.message is ''
			notification.error 'Feedback cannot be empty'
			return

		requestParams =
			feedback: $scope.feedback.message
			userAgent: navigator.userAgent
			screen: window.screen

		$scope.feedback.makingRequest = true
		rpc 'users', 'update', 'submitFeedback', requestParams, (error) ->
			$scope.feedback.makingRequest = false
			$scope.feedback.message = ''
			$scope.feedback.open = false
			notification.success 'Thank you for your feedback!'

	$scope.hideFeedback = () ->
		$scope.feedback.open = false
	
	$scope.performLogout = () ->
		return if not $scope.loggedIn

		rpc 'users', 'update', 'logout', null, (error) ->
			# this will force a refresh, rather than do html5 pushstate
			window.location.href = '/'

	$scope.$on '$routeChangeSuccess', () ->
		$scope.path = $location.path()
]
