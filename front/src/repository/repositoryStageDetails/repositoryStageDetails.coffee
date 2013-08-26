'use strict'

window.RepositoryStageDetails = ['$scope', '$location', 'rpc', 'events', 'ConsoleTextManager', 'xUnitParser', 'currentRepository', 'currentChange', 'currentStage', ($scope, $location, rpc, events, ConsoleTextManager, xUnitParser, currentRepository, currentChange, currentStage) ->
	$scope.selectedRepository = currentRepository
	$scope.selectedChange = currentChange
	$scope.selectedStage = currentStage

	$scope.output = type: null
	$scope.xunit =
		testCases: []
		orderByPredicate: 'status'
		orderByReverse: false
		maxResults: 100

	$scope.consoleTextManager = ConsoleTextManager.create()
	$scope.$on '$destroy', $scope.consoleTextManager.stopListeningToEvents

	updateUrl = () ->
		$scope.currentUrl = $location.absUrl()
	$scope.$on '$routeUpdate', updateUrl
	updateUrl()

	retrieveCurrentChangeExportUris = () ->
		$scope.exportUris = []
		return if not $scope.selectedChange.getId()?

		rpc 'changes', 'read', 'getChangeExportUris', id: $scope.selectedChange.getId(), (error, uris) ->
			$scope.exportUris = uris

	retrieveXUnitOutput = () ->
		assert.ok $scope.output.type is 'xunit'

		$scope.xunit.testCases = []
		return if not $scope.selectedStage.getId()?

		$scope.spinnerOn = true
		rpc 'buildConsoles', 'read', 'getXUnit', id: $scope.selectedStage.getId(), (error, xunitOutputs) ->
			$scope.spinnerOn = false
			$scope.xunit.testCases = xUnitParser.getTestCases xunitOutputs

	handleExportUrisAdded = (data) ->
		$scope.exportUris ?= []
		$scope.exportUris = $scope.exportUris.concat data.uris

	addedExportUrisEvents = null
	updateExportUrisAddedListener = () ->
		if addedExportUrisEvents?
			addedExportUrisEvents.unsubscribe()
			addedExportUrisEvents = null

		if $scope.selectedChange.getId()?
			addedExportUrisEvents = events('changes', 'export uris added', $scope.selectedChange.getId()).setCallback(handleExportUrisAdded).subscribe()
	$scope.$on '$destroy', () -> addedExportUrisEvents.unsubscribe() if addedExportUrisEvents?

	$scope.$watch 'selectedChange.getId()', () ->
		updateExportUrisAddedListener()
		retrieveCurrentChangeExportUris()

	$scope.$watch 'selectedStage.getId()', () ->
		$scope.output.type = null

	$scope.$watch 'selectedStage.getInformation().outputTypes', (() ->
		return if not $scope.selectedStage.getInformation()?.outputTypes?
		
		$scope.output.hasConsole = 'console' in $scope.selectedStage.getInformation().outputTypes
		$scope.output.hasXUnit = 'xunit' in $scope.selectedStage.getInformation().outputTypes

		if 'xunit' in $scope.selectedStage.getInformation().outputTypes
			$scope.output.type = 'xunit'
		else if 'console' in $scope.selectedStage.getInformation().outputTypes
			$scope.output.type = 'console'
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
