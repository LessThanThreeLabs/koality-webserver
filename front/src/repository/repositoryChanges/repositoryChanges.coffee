'use strict'

window.RepositoryChanges = ['$scope', 'changesManager', 'currentRepository', 'currentChange', 'localStorage', ($scope, changesManager, currentRepository, currentChange, localStorage) ->
	$scope.selectedRepository = currentRepository
	$scope.selectedChange = currentChange

	$scope.search =
		mode: localStorage.repositoryChangesSearchMode ? 'all'
		query: ''

	$scope.changesManager = changesManager.create [$scope.selectedRepository.getId()], $scope.search
	$scope.changesManager.listenToEvents()
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





	# handeChangeAdded = (data) ->
	# 	if doesChangeMatchQuery(data) and not getChangeWithId(data.id)?
	# 		$scope.changes ?= []
	# 		$scope.changes.unshift data

	# 	if $scope.selectedChange.getId() is data.id
	# 		$.extend true, $scope.selectedChange.getInformation(), data

	# handleChangeStarted = (data) ->
	# 	change = getChangeWithId data.id
	# 	$.extend true, change, data if change?

	# 	if $scope.selectedChange.getId() is data.id
	# 		$.extend true, $scope.selectedChange.getInformation(), data

	# handleChangeFinished = (data) ->
	# 	change = getChangeWithId data.id
	# 	$.extend true, change, data if change?

	# 	if $scope.selectedChange.getId() is data.id
	# 		$.extend true, $scope.selectedChange.getInformation(), data

	# changeAddedEvents = events('repositories', 'change added', $scope.selectedRepository.getId()).setCallback(handeChangeAdded).subscribe()
	# changeStartedEvents = events('repositories', 'change started', $scope.selectedRepository.getId()).setCallback(handleChangeStarted).subscribe()
	# changeFinishedEvents = events('repositories', 'change finished', $scope.selectedRepository.getId()).setCallback(handleChangeFinished).subscribe()
	# $scope.$on '$destroy', changeAddedEvents.unsubscribe
	# $scope.$on '$destroy', changeStartedEvents.unsubscribe
	# $scope.$on '$destroy', changeFinishedEvents.unsubscribe

	# getInitialChanges()
]
