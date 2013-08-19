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

		for change in $scope.changesManager.getChanges()
			repository = repositoryCache[change.repository.id]
			change.repository = repository if repository?

			if not repository?
				console.log 'WTF NO REPOSITORY!?!' 
				console.log change

	getChanges = () ->
		repositoryIds = $scope.repositories.map (repository) -> return repository.id
		$scope.changesManager = ChangesManager.create repositoryIds, $scope.search
		
		$scope.changesManager.listenToEvents()
		$scope.$on '$destroy', $scope.changesManager.stopListeningToEvents

		$scope.changesManager.getInitialChanges()

	getRepositories()

	$scope.$watch 'changesManager.getChanges()', () ->
		updateChangesWithRepositoryInformation()

	$scope.$watch 'search', ((newValue, oldValue) ->
		return if newValue is oldValue
		$scope.changesManager.getInitialChanges() if $scope.changesManager?
		localStorage.repositoryChangesSearchMode = $scope.search.mode
	), true

]