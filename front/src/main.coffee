'use strict'


window.Main = ['$scope', 'rpc', 'events', 'initialState', 'notification', ($scope, rpc, events, initialState, notification) ->
	repositories = []

	getRepositories = () ->
		rpc.makeRequest 'repositories', 'read', 'getRepositories', null, (error, repos) ->
			repositories = repos
			updateChangeFinishedListeners()

	createChangeFinishedHandler = (repository) ->
		return (data) -> 
			console.log 'change finished'
			console.log data

			if data.user.id is initialState.user.id
				if data.aggregateStatus is 'failed'
					notification.error "Change #{data.number} failed in repository #{repositories.name}"
				else if data.aggregateStatus is 'skipped'
					notification.error "Change #{data.number} skipped in repository #{repositories.name}"

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
