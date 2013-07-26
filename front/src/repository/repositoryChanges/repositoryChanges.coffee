'use strict'

window.RepositoryChanges = ['$scope', '$routeParams', 'changesRpc', 'events', 'currentChange', 'localStorage', 'initialState', ($scope, $routeParams, changesRpc, events, currentChange, localStorage, initialState) ->
	$scope.selectedChange = currentChange
	$scope.changes = []

	$scope.search = {}
	$scope.search.mode = localStorage.searchMode ? 'all'
	$scope.search.namesQuery = ''

	getGroupFromMode = () ->
		if $scope.search.mode is 'all' or $scope.search.mode is 'me'
			return $scope.search.mode
		if $scope.search.namesQuery is ''
			return 'all'
		return null

	getNamesFromNamesQuery = () ->
		names = $scope.search.namesQuery.toLowerCase().split ' '
		names = names.filter (name) -> name.length > 0
		return if names.length > 0 then names else null

	handleInitialChanges = (error, changes) ->
		$scope.changes = changes
		if $scope.changes.length is 0
			$scope.selectedChange.setChange null, null
		else if $scope.changes[0]?
			if not $scope.selectedChange.getId()?
				$scope.selectedChange.setChange $routeParams.repositoryId, changes[0].id

	handleMoreChanges = (error, changes) ->
		$scope.changes = $scope.changes.concat changes

	getInitialChanges = () ->
		$scope.changes = []
		changesRpc.queueRequest $routeParams.repositoryId, getGroupFromMode(), getNamesFromNamesQuery(), 0, handleInitialChanges

	getMoreChanges = () ->
		changesRpc.queueRequest $routeParams.repositoryId, getGroupFromMode(), getNamesFromNamesQuery(), $scope.changes.length, handleMoreChanges

	doesChangeMatchQuery = (change) ->
		if $scope.search.mode is 'me'
			return initialState.user.id is change.submitter?.id
		else
			return true if not getNamesFromNamesQuery()?
			return (change.submitter.firstName.toLowerCase() in getNamesFromNamesQuery()) or
				(change.submitter.lastName.toLowerCase() in getNamesFromNamesQuery())

	getChangeWithId = (id) ->
		return (change for change in $scope.changes when change.id is id)[0]

	handeChangeAdded = (data) ->
		if doesChangeMatchQuery(data) and not getChangeWithId(data.id)?
			$scope.changes.unshift data

	handleChangeStarted = (data) ->
		change = getChangeWithId data.id
		console.log 'NEED TO COPY DATA INTO CHANGE'
		# copyDataIntoChange change, data if change?

	handleChangeFinished = (data) ->
		change = getChangeWithId data.id
		console.log 'NEED TO COPY DATA INTO CHANGE'
		# copyDataIntoChange change, data if change?

		if $scope.currentChangeId is data.id
			console.log 'NEED TO COPY DATA INTO CHANGE'
			# copyDataIntoChange $scope.currentChangeInformation, data

	changeAddedEvents = events('repositories', 'change added', $routeParams.repositoryId).setCallback(handeChangeAdded).subscribe()
	changeStartedEvents = events('repositories', 'change started', $routeParams.repositoryId).setCallback(handleChangeStarted).subscribe()
	changeFinishedEvents = events('repositories', 'change finished', $routeParams.repositoryId).setCallback(handleChangeFinished).subscribe()
	$scope.$on '$destroy', changeAddedEvents.unsubscribe
	$scope.$on '$destroy', changeStartedEvents.unsubscribe
	$scope.$on '$destroy', changeFinishedEvents.unsubscribe

	$scope.searchModeClicked = (mode) ->
		$scope.search.mode = mode
		$scope.search.namesQuery = '' if mode isnt 'search'

	$scope.selectChange = (change) ->
		$scope.selectedChange.setChange $routeParams.repositoryId, change.id

	$scope.scrolledToBottom = () ->
		getMoreChanges()

	$scope.$watch 'search', ((newValue, oldValue) ->
		getInitialChanges()
		localStorage.searchMode = $scope.search.mode
	), true
]
