'use strict'

window.RepositoryStageDetails = ['$scope', '$location', 'rpc', 'events', 'ConsoleTextManager', 'xUnitParser', 'currentRepository', 'currentChange', 'currentStage', 'notification', ($scope, $location, rpc, events, ConsoleTextManager, xUnitParser, currentRepository, currentChange, currentStage, notification) ->
	$scope.selectedRepository = currentRepository
	$scope.selectedChange = currentChange
	$scope.selectedStage = currentStage

	$scope.output = type: null
	$scope.xunit =
		makingRequest: false
		testCases: []
		orderByPredicate: 'status'
		orderByReverse: false
		maxResults: 100

	$scope.debugInstance =
		makingRequest: false
		spawned: false

	$scope.consoleTextManager = ConsoleTextManager.create()
	$scope.$on '$destroy', $scope.consoleTextManager.stopListeningToEvents

	updateUrl = () ->
		$scope.currentUrl = $location.absUrl()
	$scope.$on '$routeUpdate', updateUrl
	updateUrl()

	retrieveCurrentChangeExportUris = () ->
		$scope.exportUris = []
		return if not $scope.selectedChange.getId()?

		rpc 'changes', 'read', 'getChangeExportUris', id: $scope.selectedChange.getId(), (error, exportUris) ->
			$scope.exportUris = exportUris

	retrieveXUnitOutput = () ->
		assert.ok $scope.output.type is 'xunit'

		$scope.xunit.testCases = []
		return if not $scope.selectedStage.getId()?

		$scope.xunit.makingRequest = true
		rpc 'buildConsoles', 'read', 'getXUnit', id: $scope.selectedStage.getId(), (error, xunitOutputs) ->
			$scope.xunit.makingRequest = false
			$scope.xunit.testCases = xUnitParser.getTestCases xunitOutputs

	handleExportUrisAdded = (data) ->
		return if data.resourceId isnt $scope.selectedChange.getId()
		$scope.exportUris ?= []
		$scope.exportUris = $scope.exportUris.concat data.exportMetadata

	addedExportUrisEvents = null
	updateExportUrisAddedListener = () ->
		if addedExportUrisEvents?
			addedExportUrisEvents.unsubscribe()
			addedExportUrisEvents = null

		if $scope.selectedChange.getId()?
			addedExportUrisEvents = events('changes', 'export metadata added', $scope.selectedChange.getId()).setCallback(handleExportUrisAdded).subscribe()
	$scope.$on '$destroy', () -> addedExportUrisEvents.unsubscribe() if addedExportUrisEvents?

	$scope.spawnDebugInstance = () ->
		$scope.debugInstance.makingRequest = true
		rpc 'changes', 'create', 'launchDebugInstance', id: $scope.selectedChange.getId(), (error) ->
			$scope.debugInstance.makingRequest = false
			if error? then notification.error error
			else
				$scope.debugInstance.spawned = true
				notification.success 'You will be emailed shortly with information for accessing your debug instance', 30

	$scope.$watch 'selectedChange.getId()', () ->
		updateExportUrisAddedListener()
		retrieveCurrentChangeExportUris()

	$scope.$watch 'selectedStage.getId()', () ->
		$scope.output.type = null

	$scope.$watch 'selectedStage.getInformation()', (() ->
		return if not $scope.selectedStage.getInformation()?.outputTypes?

		$scope.output.hasConsole = 'console' in $scope.selectedStage.getInformation().outputTypes
		$scope.output.hasXUnit = 'xunit' in $scope.selectedStage.getInformation().outputTypes

		return if $scope.output.type?

		if 'xunit' in $scope.selectedStage.getInformation().outputTypes
			$scope.output.type = 'xunit'
		else if 'console' in $scope.selectedStage.getInformation().outputTypes
			$scope.output.type = 'console'
		else
			console.error 'No output type provided'
	), true

	$scope.$watch 'selectedStage.getId() + output.type', () ->
		return if not $scope.selectedStage.getId()?

		$scope.consoleTextManager.clear()
		$scope.xunit.testCases = []

		if $scope.output.type is 'console'
			$scope.consoleTextManager.setStageId $scope.selectedStage.getId()
			$scope.consoleTextManager.listenToEvents()
			$scope.consoleTextManager.retrieveInitialLines()

		if $scope.output.type is 'xunit'
			retrieveXUnitOutput()
]
