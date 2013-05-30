'use strict'

window.Analytics = ['$scope', 'rpc', 'events', ($scope, rpc, events) ->
	$scope.changes = []

	$scope.graph = 'passedAndFailed'
	$scope.graphSelected = (newValue) -> $scope.graph = newValue

	allRepository = {id: -1, name: 'All'}
	$scope.repository = allRepository
	$scope.repositories = [allRepository]
	$scope.repositorySelected = (newValue) -> $scope.repository = newValue

	$scope.duration = 7
	$scope.durationSelected = (newValue) -> $scope.duration = newValue

	$scope.interval = 'hours'
	$scope.intervalSelected = (newValue) -> $scope.interval = newValue

	$scope.viewingMode = 'line'
	$scope.viewingModeSelected = (newValue) -> $scope.viewingMode = newValue

	getRepositories = () ->
		rpc.makeRequest 'repositories', 'read', 'getRepositories', null, (error, repositories) ->
			$scope.$apply () ->
				$scope.repositories = [allRepository].concat repositories
				getChanges()

	getChanges = () ->
		return if $scope.repositories.every (repository) -> return repository.id < 0

		getRepositoriesToRequest = () ->
			if $scope.repository.id >= 0 then return [$scope.repository.id]
			else
				return $scope.repositories
					.map((repository) -> return repository.id)
					.filter((repositoryId) -> repositoryId >= 0)

		timeInDay = 24 * 60 * 60 * 1000
		currentTime = (new Date()).getTime()

		$scope.changes = []

		requestParams =
			repositories: getRepositoriesToRequest()
			timestamp: currentTime - $scope.duration * timeInDay
		rpc.makeRequest 'changes', 'read', 'getChangesFromTimestamp', requestParams, (error, changes) ->
			$scope.$apply () ->
				$scope.changes = changes.filter (change) -> return change.endTime?

	getRepositories()

	$scope.$watch 'repository', () -> getChanges()
	$scope.$watch 'duration', () -> getChanges()

	$scope.$watch 'changes', () -> console.log $scope.changes
]