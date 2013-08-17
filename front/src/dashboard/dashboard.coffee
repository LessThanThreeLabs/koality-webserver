'use strict'

window.Dashboard = ['$scope', '$location', 'rpc', 'events', 'localStorage', 'notification', ($scope, $location, rpc, events, localStorage, notification) ->
	repositoryCache = {}

	$scope.search =
		mode: localStorage.dashboardSearchMode ? 'all'
		query: ''

	getRepositories = () ->
		rpc 'repositories', 'read', 'getRepositories', null, (error, repositories) ->
			if error? then notification.error error
			else
				$scope.repositories = repositories
				createRepositoryCache()
				updateChangesWithRepositoryInformation()

	getChanges = () ->
		requestParams =
			repositoryId: 1
			group: 'all'
			names: null
			startIndex: 0
			numToRetrieve: 100
		rpc 'changes', 'read', 'getChanges', requestParams, (error, changes) ->
			if error? then notification.error error
			else
				$scope.changes = changes
				updateChangesWithRepositoryInformation()

	createRepositoryCache = () ->
		for repository in $scope.repositories
			repositoryCache[repository.id] = repository

	updateChangesWithRepositoryInformation = () ->
		assert.ok repositoryCache?
		return if not $scope.changes? or $scope.changes.length < 1

		for change in $scope.changes
			repository = repositoryCache[change.repository.id]
			change.repository = repository if repository?

	getChangeWithId = (id) ->
		return (change for change in $scope.graphOptions.changes when change.id is id)[0]

	# handleChangeFinished = (data) ->
	# 	$scope.graphOptions.changes.push data if not getChangeWithId(data.id)?

	# changeFinishedListeners = []
	# updateChangeFinishedListeners = () ->
	# 	changeFinishedListener.unsubscribe() for changeFinishedListener in changeFinishedListeners
	# 	changeFinishedListeners = []

	# 	return if $scope.options.duration.value isnt 'today'

	# 	for repositoryId in getRepositoryIdsToDisplay()
	# 		console.log repositoryId
	# 		changeFinishedListener = events('repositories', 'change finished', repositoryId).setCallback(handleChangeFinished).subscribe()
	# 		changeFinishedListeners.push changeFinishedListener
	# $scope.$on '$destroy', () -> changeFinishedListener.unsubscribe() for changeFinishedListener in changeFinishedListeners

	getRepositories()
	getChanges()

	$scope.searchModeClicked = (mode) ->
		$scope.search.mode = mode
		$scope.search.query = '' if mode isnt 'search'

	$scope.$watch 'search', ((newValue, oldValue) ->
		return if newValue is oldValue
		# getInitialChanges()
		localStorage.dashboardSearchMode = $scope.search.mode
	), true
]