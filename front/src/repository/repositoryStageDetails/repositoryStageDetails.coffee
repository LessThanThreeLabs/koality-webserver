'use strict'

window.RepositoryStageDetails = ['$scope', '$location', 'rpc', 'events', 'xunit', 'stringHasher', 'integerConverter', 'currentRepository', 'currentChange', 'currentStage', ($scope, $location, rpc, events, xunit, stringHasher, integerConverter, currentRepository, currentChange, currentStage) ->
	$scope.selectedRepository = currentRepository
	$scope.selectedChange = currentChange
	$scope.selectedStage = currentStage

	$scope.lines = {}

	$scope.jUnitOrderByPredicate = 'status'
	$scope.jUnitOrderByReverse = false

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
		assert.ok $scope.outputType is 'lines'

		$scope.lines = {}
		return if not $scope.selectedStage.getId()?
		
		$scope.spinnerOn = true
		rpc 'buildConsoles', 'read', 'getLines', id: $scope.selectedStage.getId(), (error, lines) ->
			$scope.spinnerOn = false
			processLines lines

	retrieveXUnitOutput = () ->
		assert.ok $scope.outputType is 'xunit'

		$scope.lines = {}
		return if not $scope.selectedStage.getId()?

		$scope.spinnerOn = true
		rpc 'buildConsoles', 'read', 'getJUnit', id: $scope.selectedStage.getId(), (error, xunitOutputs) ->
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

			if $scope.lines[lineNumber]?
				$scope.lines[lineNumber].text = lineText
				$scope.lines[lineNumber].hash = lineHash
			else
				$scope.lines[lineNumber] =
					text: lineText
					hash: lineHash

	clearOutput = () ->
		$scope.lines = {}
		$scope.xunit = null

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

		if $scope.selectedStage.getId()? and $scope.outputType is 'lines'
			addedLineEvents = events('buildConsoles', 'new output', $scope.selectedStage.getId()).setCallback(handleLinesAdded).subscribe()
	$scope.$on '$destroy', () -> addedLineEvents.unsubscribe() if addedLineEvents?

	$scope.$watch 'outputType', () ->
		console.log 'this does not have a . , so angular will probably mess up when setting this variable. Should create state object or something...'
		clearOutput()

		updateAddedLineListener()
		if $scope.outputType is 'lines' then retrieveLines()
		if $scope.outputType is 'xunit' then retrieveXUnitOutput()

	$scope.$watch 'selectedChange.getId()', () ->
		updateExportUrisAddedListener()
		retrieveCurrentChangeExportUris()

	$scope.$watch 'selectedStage.getId()', () ->
		$scope.outputType = null

	$scope.$watch 'selectedStage.getInformation()', (() ->
		return if not $scope.selectedStage.getInformation()?

		if $scope.selectedStage.getInformation().hasXUnit then $scope.outputType = 'xunit'
		else $scope.outputType = 'lines'
	), true
]
