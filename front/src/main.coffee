'use strict'


window.Main = ['$scope', 'rpc', 'events', 'initialState', 'notification', ($scope, rpc, events, initialState, notification) ->
	repositories = []

	getRepositories = () ->
		rpc.makeRequest 'repositories', 'read', 'getRepositories', null, (error, repos) ->
			repositories = repos
			updateChangeFinishedListeners()

	createChangeFinishedHandler = (repository) ->
		return (data) -> 
			if data.submitter.id is initialState.user.id
				message = "<a href='/repository/#{repository.id}?change=#{data.id}'>Change #{data.number}</a> #{data.aggregateStatus}"
				if data.aggregateStatus is 'passed' then notification.success message
				else if data.aggregateStatus is 'failed' then notification.error message
				else if data.aggregateStatus is 'skipped' then notification.warning message

	changeFinishedListeners = []
	updateChangeFinishedListeners = () ->
		changeFinishedListener.unsubscribe() for changeFinishedListener in changeFinishedListeners
		changeFinishedListeners = []

		return if not initialState.loggedIn

		for repository in repositories
			changeFinishedListener = events.listen('repositories', 'change finished', repository.id).setCallback(createChangeFinishedHandler(repository)).subscribe()
			changeFinishedListeners.push changeFinishedListener
	$scope.$on '$destroy', () -> changeFinishedListener.unsubscribe() for changeFinishedListener in changeFinishedListeners

	getRepositories() if initialState.loggedIn
]
