'use strict'

window.Dashboard = ['$scope', 'rpc', 'events', 'ChangesManager', 'localStorage', ($scope, rpc, events, ChangesManager, localStorage) ->
	repositoryCache = {}

	$scope.search =
		mode: localStorage.repositoryChangesSearchMode ? 'all'
		query: ''

	getRepositories = () ->
		rpc 'repositories', 'read', 'getRepositories', null, (error, repositories) ->
			if error? then notification.error error
			else
				$scope.repositories = repositories
				createRepositoryCache()
				getChanges()

	createRepositoryCache = () ->
		for repository in $scope.repositories
			repositoryCache[repository.id] = repository

	updateChangesWithRepositoryInformation = () ->
		assert.ok repositoryCache?

		return if not $scope.changesManager?

		for change in $scope.changesManager.getChanges()
			repository = repositoryCache[change.repository.id]
			change.repository = repository if repository?

	getChanges = () ->
		repositoryIds = $scope.repositories.map (repository) -> return repository.id
		$scope.changesManager = ChangesManager.create repositoryIds, $scope.search
		
		$scope.changesManager.listenToEvents()
		$scope.$on '$destroy', $scope.changesManager.stopListeningToEvents

		$scope.changesManager.retrieveInitialChanges()

	getRepositories()

	$scope.$watch 'changesManager.getChanges()', (() ->
		updateChangesWithRepositoryInformation()
	), true

	$scope.$watch 'search', ((newValue, oldValue) ->
		return if newValue is oldValue
		$scope.changesManager.retrieveInitialChanges() if $scope.changesManager?
		localStorage.repositoryChangesSearchMode = $scope.search.mode
	), true

]