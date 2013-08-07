'use strict'

window.RepositoryStages = ['$scope', '$routeParams', 'rpc', 'events', 'currentChange', 'currentStage', ($scope, $routeParams, rpc, events, currentChange, currentStage) ->
	$scope.selectedChange = currentChange
	$scope.selectedStage = currentStage

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
		if not $scope.selectedChange.getId()?
			$scope.stages = null
			$scope.selectedStage.setStage null, null
			return

		rpc 'buildConsoles', 'read', 'getBuildConsoles', changeId: $scope.selectedChange.getId(), (error, buildConsoles) ->
			$scope.stages = buildConsoles

			if $scope.stages.length is 0
				$scope.selectedStage.setStage null, null

			if not $scope.selectedStage.getId()?
				$scope.selectedStage.setSummary()

			if $scope.selectedStage.getId()? and not getStageWithId($scope.selectedStage.getId())?
				$scope.selectedStage.setSummary()

	getStageWithId = (id) ->
		return null if not $scope.stages?
		return (stage for stage in $scope.stages when stage.id is id)[0]

	handleBuildConsoleAdded = (data) ->
		$scope.stages ?= []
		$scope.stages.push data if not getStageWithId(data.id)?

	handleBuildConsoleStatusUpdate = (data) ->
		stage = getStageWithId data.id
		return if not stage?

		stage.status = data.status

		if stage.status is 'failed' and isMirrorStage stage, $scope.selectedStage.getInformation()
			$scope.selectedStage.setStage $routeParams.repositoryId, stage.id

	buildConsoleAddedEvents = null
	updateBuildConsoleAddedListener = () ->
		if buildConsoleAddedEvents?
			buildConsoleAddedEvents.unsubscribe()
			buildConsoleAddedEvents = null

		if $scope.selectedChange.getId()?
			buildConsoleAddedEvents = events('changes', 'new build console', $scope.selectedChange.getId()).setCallback(handleBuildConsoleAdded).subscribe()
	$scope.$on '$destroy', () -> buildConsoleAddedEvents.unsubscribe() if buildConsoleAddedEvents?

	buildConsoleStatusUpdateEvents = null
	updateBuildConsoleStatusListener = () ->
		if buildConsoleStatusUpdateEvents?
			buildConsoleStatusUpdateEvents.unsubscribe()
			buildConsoleStatusUpdateEvents = null

		if $scope.selectedChange.getId()?
			buildConsoleStatusUpdateEvents = events('changes', 'return code added', $scope.selectedChange.getId()).setCallback(handleBuildConsoleStatusUpdate).subscribe()
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
		return true if stage.id is $scope.selectedStage.getId()
		return false if isMirrorStage stage, $scope.selectedStage.getInformation()
		return true if stage.id is getMostImportantStageWithTypeAndName(stage.type, stage.name).id
		return false

	$scope.selectStage = (stage) ->
		$scope.selectedStage.setStage $routeParams.repositoryId, stage?.id

	$scope.$watch 'selectedChange.getId()', (newValue, oldValue) ->
		updateBuildConsoleAddedListener()
		updateBuildConsoleStatusListener()
		retrieveStages()
]