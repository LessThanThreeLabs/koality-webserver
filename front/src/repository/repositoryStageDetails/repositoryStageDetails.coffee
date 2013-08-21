'use strict'

window.RepositoryStageDetails = ['$scope', '$location', 'rpc', 'events', 'xunit', 'stringHasher', 'integerConverter', 'currentRepository', 'currentChange', 'currentStage', ($scope, $location, rpc, events, xunit, stringHasher, integerConverter, currentRepository, currentChange, currentStage) ->
	$scope.selectedRepository = currentRepository
	$scope.selectedChange = currentChange
	$scope.selectedStage = currentStage

	$scope.output =
		type: null
		lines: {}
		xunit:
			testCases: []
			orderByPredicate: 'status'
			orderByReverse: false

	updateUrl = () ->
		$scope.currentUrl = $location.absUrl()
	$scope.$on '$routeUpdate', updateUrl
	updateUrl()

	retrieveCurrentChangeExportUris = () ->
		$scope.exportUris = []
		return if not $scope.selectedChange.getId()?

		rpc 'changes', 'read', 'getChangeExportUris', id: $scope.selectedChange.getId(), (error, uris) ->
			$scope.exportUris = uris

	retrieveLines = () ->
		assert.ok $scope.output.type is 'lines'

		$scope.output.lines = {}
		return if not $scope.selectedStage.getId()?
		
		$scope.spinnerOn = true
		rpc 'buildConsoles', 'read', 'getLines', id: $scope.selectedStage.getId(), (error, lines) ->
			$scope.spinnerOn = false
			processLines lines

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

	handleLinesAdded = (data) ->
		processLines data

	processLines = (data) ->
		for lineNumber, lineText of data
			lineNumber = integerConverter.toInteger lineNumber
			lineHash = stringHasher.hash lineText

			if $scope.output.lines[lineNumber]?
				$scope.output.lines[lineNumber].text = lineText
				$scope.output.lines[lineNumber].hash = lineHash
			else
				$scope.output.lines[lineNumber] =
					text: lineText
					hash: lineHash

	addedExportUrisEvents = null
	updateExportUrisAddedListener = () ->
		if addedExportUrisEvents?
			addedExportUrisEvents.unsubscribe()
			addedExportUrisEvents = null

		if $scope.selectedChange.getId()?
			addedExportUrisEvents = events('changes', 'export uris added', $scope.selectedChange.getId()).setCallback(handleExportUrisAdded).subscribe()
	$scope.$on '$destroy', () -> addedExportUrisEvents.unsubscribe() if addedExportUrisEvents?

	addedLineEvents = null
	updateAddedLineListener = () ->
		if addedLineEvents?
			addedLineEvents.unsubscribe()
			addedLineEvents = null

		if $scope.selectedStage.getId()? and $scope.output.type is 'lines'
			addedLineEvents = events('buildConsoles', 'new output', $scope.selectedStage.getId()).setCallback(handleLinesAdded).subscribe()
	$scope.$on '$destroy', () -> addedLineEvents.unsubscribe() if addedLineEvents?

	$scope.$watch 'selectedChange.getId()', () ->
		updateExportUrisAddedListener()
		retrieveCurrentChangeExportUris()

	$scope.$watch 'selectedStage.getId()', () ->
		$scope.output.type = null if not $scope.selectedStage.getInformation()?

	$scope.$watch 'selectedStage.getInformation()', (() ->
		return if not $scope.selectedStage.getInformation()?

		if $scope.selectedStage.getInformation().hasXUnit then $scope.output.type = 'xunit'
		else $scope.output.type = 'lines'
	), true

	$scope.$watch 'selectedStage.getId() + output.type', () ->
		$scope.output.lines = {}
		$scope.output.xunit.testCases = []

		updateAddedLineListener()
		if $scope.output.type is 'lines' then retrieveLines()
		if $scope.output.type is 'xunit' then retrieveXUnitOutput()
]
