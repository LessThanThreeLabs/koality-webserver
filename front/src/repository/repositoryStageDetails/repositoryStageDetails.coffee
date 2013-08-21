'use strict'

window.RepositoryStageDetails = ['$scope', '$location', 'rpc', 'events', 'ConsoleTextManager', 'xunit', 'currentRepository', 'currentChange', 'currentStage', ($scope, $location, rpc, events, ConsoleTextManager, xunit, currentRepository, currentChange, currentStage) ->
	$scope.selectedRepository = currentRepository
	$scope.selectedChange = currentChange
	$scope.selectedStage = currentStage

	$scope.output =
		type: null
		xunit:
			testCases: []
			orderByPredicate: 'status'
			orderByReverse: false

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

		$scope.output.xunit.testCases = []
		return if not $scope.selectedStage.getId()?

		$scope.spinnerOn = true
		rpc 'buildConsoles', 'read', 'getXUnit', id: $scope.selectedStage.getId(), (error, xunitOutputs) ->
			$scope.spinnerOn = false
			$scope.xunit = xunit.getTestCases xunitOutputs

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
		$scope.consoleTextManager.setStageId $scope.selectedStage.getId()
		$scope.consoleTextManager.stopListeningToEvents()

		$scope.output.type = null if not $scope.selectedStage.getInformation()?

	$scope.$watch 'selectedStage.getInformation()', (() ->
		return if not $scope.selectedStage.getInformation()?

		if $scope.selectedStage.getInformation().hasXUnit then $scope.output.type = 'xunit'
		else $scope.output.type = 'lines'
	), true

	$scope.$watch 'selectedStage.getId() + output.type', () ->
		$scope.output.xunit.testCases = []

		if $scope.selectedStage.getId()?
			if $scope.output.type is 'lines'
				$scope.consoleTextManager.listenToEvents()
				$scope.consoleTextManager.retrieveInitialLines()
			
			if $scope.output.type is 'xunit'
				retrieveXUnitOutput()
]
