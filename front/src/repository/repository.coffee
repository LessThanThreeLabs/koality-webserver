'use strict'

copyDataIntoChange = (change, data) ->
	assert.ok change? and typeof change is 'object'
	assert.ok data? and typeof data is 'object'

	change.aggregateStatus = data.aggregateStatus
	change.verificationStatus = data.verificationStatus
	change.mergeStatus = data.mergeStatus
	change.createTime = data.createTime
	change.startTime = data.startTime
	change.endTime = data.endTime


window.Repository = ['$scope', '$location', '$routeParams', 'rpc', 'events', 'integerConverter', ($scope, $location, $routeParams, rpc, events, integerConverter) ->
	retrieveRepositoryInformation = () ->
		rpc.makeRequest 'repositories', 'read', 'getMetadata', id: $routeParams.repositoryId, (error, repositoryInformation) ->
			$scope.$apply () ->
				$scope.repository = repositoryInformation

	retrieveCurrentChangeInformation = () ->
		$scope.currentChangeInformation = null
		return if not $scope.currentChangeId?

		requestData =
			repositoryId: integerConverter.toInteger $routeParams.repositoryId
			id: $scope.currentChangeId

		rpc.makeRequest 'changes', 'read', 'getMetadata', requestData, (error, changeInformation) ->
			$scope.$apply () ->
				$scope.currentChangeInformation = changeInformation
				$scope.showSkipped = false if $scope.currentChangeInformation.aggregateStatus isnt 'skipped'
				$scope.showMerge = false if not $scope.currentChangeInformation.mergeStatus?
				$scope.showDebug = false if $scope.currentChangeInformation.aggregateStatus isnt 'failed'

	retrieveCurrentStageInformation = () ->
		$scope.currentStageInformation = null
		return if not $scope.currentStageId?

		requestData =
			repositoryId: integerConverter.toInteger $routeParams.repositoryId
			id: $scope.currentStageId

		rpc.makeRequest 'buildConsoles', 'read', 'getBuildConsole', requestData, (error, stageInformation) ->
			$scope.$apply () ->
				$scope.currentStageInformation = stageInformation

	syncToRouteParams = () ->
		$scope.currentChangeId = integerConverter.toInteger $routeParams.change
		$scope.currentStageId = integerConverter.toInteger $routeParams.stage
		$scope.showSkipped = $routeParams.skipped?
		$scope.showMerge = $routeParams.merge?
		$scope.showDebug = $routeParams.debug?
	$scope.$on '$routeUpdate', syncToRouteParams
	syncToRouteParams()

	$scope.selectChange = (change) ->
		$scope.currentChangeId = change?.id
		$scope.currentStageId = null
		$scope.showSkipped = false
		$scope.showMerge = false
		$scope.showDebug = false

	$scope.selectStage = (stage) ->
		$scope.currentStageId = stage?.id
		$scope.showSkipped = false
		$scope.showMerge = false
		$scope.showDebug = false

	$scope.selectSkipped = () ->
		$scope.currentStageId = null
		$scope.showSkipped = true
		$scope.showMerge = false
		$scope.showDebug = false

	$scope.selectMerge = () ->
		$scope.currentStageId = null
		$scope.showSkipped = false
		$scope.showMerge = true
		$scope.showDebug = false

	$scope.selectDebug = () ->
		$scope.currentStageId = null
		$scope.showSkipped = false
		$scope.showMerge = false
		$scope.showDebug = true

	$scope.$watch 'currentChangeId', (newValue, oldValue) ->
		# updateMergeStatusListener()
		retrieveCurrentChangeInformation()
		$location.search 'change', newValue ? null

	$scope.$watch 'currentStageId', (newValue, oldValue) ->
		retrieveCurrentStageInformation()
		$location.search 'stage', newValue ? null

	$scope.$watch 'showSkipped', (newValue, oldValue) ->
		$location.search 'skipped', if newValue then true else null

	$scope.$watch 'showMerge', (newValue, oldValue) ->
		$location.search 'merge', if newValue then true else null

	$scope.$watch 'showDebug', (newValue, oldValue) ->
		$location.search 'debug', if newValue then true else null

	retrieveRepositoryInformation()
]

window.RepositoryChanges = ['$scope', '$routeParams', 'changesRpc', 'events', 'localStorage', ($scope, $routeParams, changesRpc, events, localStorage) ->
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

	handleInitialChanges = (error, changes) -> $scope.$apply () ->
		$scope.changes = changes
		if $scope.changes.length is 0
			$scope.selectChange null
		else if $scope.changes[0]?
			$scope.selectChange changes[0] if not $scope.currentChangeId?

	handleMoreChanges = (error, changes) -> $scope.$apply () ->
		$scope.changes = $scope.changes.concat changes

	getInitialChanges = () ->
		$scope.changes = []
		changesRpc.queueRequest $routeParams.repositoryId, getGroupFromMode(), getNamesFromNamesQuery(), 0, handleInitialChanges

	getMoreChanges = () ->
		changesRpc.queueRequest $routeParams.repositoryId, getGroupFromMode(), getNamesFromNamesQuery(), $scope.changes.length, handleMoreChanges

	doesChangeMatchQuery = (change) ->
		return true if not getNamesFromNamesQuery()?
		return (change.submitter.firstName.toLowerCase() in getNamesFromNamesQuery()) or
			(change.submitter.lastName.toLowerCase() in getNamesFromNamesQuery())

	getChangeWithId = (id) ->
		return (change for change in $scope.changes when change.id is id)[0]

	handeChangeAdded = (data) -> $scope.$apply () ->
		if doesChangeMatchQuery(data) and not getChangeWithId(data.id)?
			$scope.changes.unshift data

	handleChangeStarted = (data) -> $scope.$apply () ->
		change = getChangeWithId data.id
		copyDataIntoChange change, data if change?

	handleChangeFinished = (data) -> $scope.$apply () ->
		change = getChangeWithId data.id
		copyDataIntoChange change, data if change?

		if change?.aggregateStatus is 'passed'
			change.animate = true
			setTimeout (() -> $scope.$apply () -> change.animate = false), 3000

		if $scope.currentChangeId is data.id
			copyDataIntoChange $scope.currentChangeInformation, data

	changeAddedEvents = events.listen('repositories', 'change added', $routeParams.repositoryId).setCallback(handeChangeAdded).subscribe()
	changeStartedEvents = events.listen('repositories', 'change started', $routeParams.repositoryId).setCallback(handleChangeStarted).subscribe()
	changeFinishedEvents = events.listen('repositories', 'change finished', $routeParams.repositoryId).setCallback(handleChangeFinished).subscribe()
	$scope.$on '$destroy', changeAddedEvents.unsubscribe
	$scope.$on '$destroy', changeStartedEvents.unsubscribe
	$scope.$on '$destroy', changeFinishedEvents.unsubscribe

	$scope.searchModeClicked = (mode) ->
		$scope.search.mode = mode
		$scope.search.namesQuery = '' if mode isnt 'search'

	$scope.scrolledToBottom = () ->
		getMoreChanges()

	$scope.$watch 'search', ((newValue, oldValue) ->
		getInitialChanges()
		localStorage.searchMode = $scope.search.mode
	), true
]


window.RepositoryStages = ['$scope', 'rpc', 'events', ($scope, rpc, events) ->
	$scope.stages = []

	isStageIdInStages = (stageId) ->
		stage = (stage for stage in $scope.stages when stage.id is stageId)[0]
		return stage?

	getMostImportantStageWithTypeAndName = (type, name) ->
		mostImportantStage = null

		for potentialStage in $scope.stages
			continue if potentialStage.type isnt type or potentialStage.name isnt name

			if not mostImportantStage?
				mostImportantStage = potentialStage
			else
				if potentialStage.status is 'failed' and mostImportantStage.status is 'failed'
					mostImportantStage = potentialStage if potentialStage.id < mostImportantStage.id
				else if potentialStage.status is 'failed' and mostImportantStage.status isnt 'failed'
					mostImportantStage = potentialStage
				else if potentialStage.status isnt 'failed' and mostImportantStage.status isnt 'failed'
					mostImportantStage = potentialStage if potentialStage.id < mostImportantStage.id

		return mostImportantStage

	isMirrorStage = (stage1, stage2) ->
		return false if not stage1? or not stage2?
		return stage1.type is stage2.type and stage1.name is stage2.name

	retrieveStages = () ->
		$scope.stages = []
		return if not $scope.currentChangeId?

		$scope.retrievingStages = true
		rpc.makeRequest 'buildConsoles', 'read', 'getBuildConsoles', changeId: $scope.currentChangeId, (error, buildConsoles) ->
			$scope.$apply () ->
				$scope.retrievingStages = false
				$scope.stages = buildConsoles

				if $scope.stages.length is 0
					$scope.selectStage null

				if $scope.currentStageId? and not isStageIdInStages $scope.currentStageId
					$scope.selectStage null

	getStageWithId = (id) ->
		return (stage for stage in $scope.stages when stage.id is id)[0]

	handleBuildConsoleAdded = (data) -> $scope.$apply () ->
		$scope.stages.push data if not getStageWithId(data.id)?

	handleBuildConsoleStatusUpdate = (data) -> $scope.$apply () ->
		stage = getStageWithId data.id
		stage.status = data.status if stage?

		if stage.status is 'failed' and isMirrorStage stage, $scope.currentStageInformation
			$scope.selectStage stage

	buildConsoleAddedEvents = null
	updateBuildConsoleAddedListener = () ->
		if buildConsoleAddedEvents?
			buildConsoleAddedEvents.unsubscribe()
			buildConsoleAddedEvents = null

		if $scope.currentChangeId?
			buildConsoleAddedEvents = events.listen('changes', 'new build console', $scope.currentChangeId).setCallback(handleBuildConsoleAdded).subscribe()
	$scope.$on '$destroy', () -> buildConsoleAddedEvents.unsubscribe() if buildConsoleAddedEvents?

	buildConsoleStatusUpdateEvents = null
	updateBuildConsoleStatusListener = () ->
		if buildConsoleStatusUpdateEvents?
			buildConsoleStatusUpdateEvents.unsubscribe()
			buildConsoleStatusUpdateEvents = null

		if $scope.currentChangeId?
			buildConsoleStatusUpdateEvents = events.listen('changes', 'return code added', $scope.currentChangeId).setCallback(handleBuildConsoleStatusUpdate).subscribe()
	$scope.$on '$destroy', () -> buildConsoleStatusUpdateEvents.unsubscribe() if buildConsoleStatusUpdateEvents?

	$scope.stageSort = (stage) ->
		if stage.type is 'setup'
			return 10000 + stage.orderNumber
		else if stage.type is 'compile'
			return 20000 + stage.orderNumber
		else if stage.type is 'testFactory'
			return 30000 + stage.orderNumber
		else if stage.type is 'test'
			return 40000 + stage.orderNumber
		else
			console.error 'Cannot sort stage'
			return 50000

	$scope.shouldStageBeVisible = (stage) ->
		return true if stage.id is $scope.currentStageId
		return false if isMirrorStage stage, $scope.currentStageInformation
		return true if stage.id is getMostImportantStageWithTypeAndName(stage.type, stage.name).id
		return false

	$scope.$watch 'currentChangeId', (newValue, oldValue) ->
		updateBuildConsoleAddedListener()
		updateBuildConsoleStatusListener()
		retrieveStages()
]


window.RepositoryStageDetails = ['$scope', '$location', 'rpc', 'events', ($scope, $location, rpc, events) ->
	updateUrl = () ->
		$scope.currentUrl = $location.absUrl()
	$scope.$on '$routeUpdate', updateUrl
	updateUrl()

	retrieveCurrentChangeExportUris = () ->
		$scope.exportUris = []
		return if not $scope.currentChangeId?

		rpc.makeRequest 'changes', 'read', 'getChangeExportUris', id: $scope.currentChangeId, (error, uris) ->
			$scope.$apply () ->
				$scope.exportUris = uris

	retrieveLines = () ->
		$scope.lines = []
		return if not $scope.currentStageId?
		$scope.spinnerOn = true

		rpc.makeRequest 'buildConsoles', 'read', 'getLines', id: $scope.currentStageId, (error, lines) ->
			$scope.$apply () ->
				$scope.spinnerOn = false
				for lineNumber, lineText of lines
					addLine lineNumber, lineText

	handleExportUrisAdded = (data) -> $scope.$apply () ->
		$scope.exportUris ?= []
		$scope.exportUris = $scope.exportUris.concat data.uris

	addLine = (lineNumber, lineText) ->
		$scope.lines[lineNumber-1] = lineText

	handleLinesAdded = (data) -> $scope.$apply () ->
		$scope.lines ?= []
		for lineNumber, lineText of data
			addLine lineNumber, lineText

	addedExportUrisEvents = null
	updateExportUrisAddedListener = () ->
		if addedExportUrisEvents?
			addedExportUrisEvents.unsubscribe()
			addedExportUrisEvents = null

		if $scope.currentChangeId?
			addedExportUrisEvents = events.listen('changes', 'export uris added', $scope.currentChangeId).setCallback(handleExportUrisAdded).subscribe()
	$scope.$on '$destroy', () -> addedExportUrisEvents.unsubscribe() if addedExportUrisEvents?

	addedLineEvents = null
	updateAddedLineListener = () ->
		if addedLineEvents?
			addedLineEvents.unsubscribe()
			addedLineEvents = null

		if $scope.currentStageId?
			addedLineEvents = events.listen('buildConsoles', 'new output', $scope.currentStageId).setCallback(handleLinesAdded).subscribe()
	$scope.$on '$destroy', () -> addedLineEvents.unsubscribe() if addedLineEvents?

	$scope.$watch 'currentChangeId', (newValue, oldValue) ->
		updateExportUrisAddedListener()
		retrieveCurrentChangeExportUris()

	$scope.$watch 'currentStageId', (newValue, oldValue) ->
		updateAddedLineListener()
		retrieveLines()
]
