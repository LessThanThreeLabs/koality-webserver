'use strict'

window.RepositoryChanges = ['$scope', 'changesManager', 'currentRepository', 'currentChange', 'localStorage', ($scope, changesManager, currentRepository, currentChange, localStorage) ->
	$scope.selectedRepository = currentRepository
	$scope.selectedChange = currentChange

	$scope.search =
		mode: localStorage.repositoryChangesSearchMode ? 'all'
		query: ''

	$scope.changesManager = changesManager.create [$scope.selectedRepository.getId()], $scope.search
	
	$scope.changesManager.listenToEvents()
	$scope.$on '$destroy', $scope.changesManager.stopListeningToEvents

	$scope.changesManager.getInitialChanges()

	$scope.selectChange = (change) ->
		$scope.selectedChange.setId $scope.selectedRepository.getId(), change.id
		$scope.selectedChange.setInformation change

	$scope.$watch 'changesManager.getChanges()', () ->
		if not $scope.selectedChange.getId()? and $scope.changesManager.getChanges().length > 0
			firstChange = $scope.changesManager.getChanges()[0]
			$scope.selectedChange.setId $scope.selectedRepository.getId(), firstChange.id
			$scope.selectedChange.setInformation firstChange

	$scope.$watch 'search', ((newValue, oldValue) ->
		return if newValue is oldValue
		$scope.changesManager.getInitialChanges()
		localStorage.repositoryChangesSearchMode = $scope.search.mode
	), true
]
