'use strict'

window.RepositoryStageDetails = ['$scope', '$location', 'rpc', 'events', 'currentRepository', 'currentChange', 'currentStage', ($scope, $location, rpc, events, currentRepository, currentChange, currentStage) ->
	$scope.selectedRepository = currentRepository
	$scope.selectedChange = currentChange
	$scope.selectedStage = currentStage

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

		$scope.lines = null
		return if not $scope.selectedStage.getId()?
		
		$scope.spinnerOn = true

		console.log 'requesting lines'
		rpc 'buildConsoles', 'read', 'getLines', id: $scope.selectedStage.getId(), (error, lines) ->
			$scope.spinnerOn = false

			$scope.lines ?= []
			for lineNumber, lineText of lines
				addLine lineNumber, lineText

	retrieveJUnitOutput = () ->
		assert.ok $scope.outputType is 'junit'

		$scope.lines = null
		return if not $scope.selectedStage.getId()?

		$scope.spinnerOn = true

		console.log 'requesting junit'
		rpc 'buildConsoles', 'read', 'getJUnit', id: $scope.selectedStage.getId(), (error, junit) ->
			$scope.spinnerOn = false
			$scope.junit = junit

	handleExportUrisAdded = (data) ->
		$scope.exportUris ?= []
		$scope.exportUris = $scope.exportUris.concat data.uris

	addLine = (lineNumber, lineText) ->
		$scope.lines[lineNumber-1] = lineText

	handleLinesAdded = (data) ->
		$scope.lines ?= []
		for lineNumber, lineText of data
			addLine lineNumber, lineText

	clearOutput = () ->
		$scope.outputType = null
		$scope.lines = null
		$scope.junit = null

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

	$scope.selectOutputType = (outputType) =>
		return if $scope.outputType is outputType

		clearOutput()
		$scope.outputType = outputType

		updateAddedLineListener()
		if $scope.outputType is 'lines' then retrieveLines()
		if $scope.outputType is 'junit' then retrieveJUnitOutput()

	$scope.$watch 'selectedChange.getId()', () ->
		updateExportUrisAddedListener()
		retrieveCurrentChangeExportUris()

	$scope.$watch 'selectedStage.getId()', () ->
		clearOutput()
		updateAddedLineListener()

	$scope.$watch 'selectedStage.getInformation()', (() ->
		return if not $scope.selectedStage.getInformation()?

		if $scope.selectedStage.getInformation().hasJUnit then $scope.selectOutputType 'junit'
		else $scope.selectOutputType 'lines'
	), true
]
