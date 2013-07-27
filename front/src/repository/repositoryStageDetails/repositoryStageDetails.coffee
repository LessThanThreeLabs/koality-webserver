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
		$scope.lines = []
		return if not $scope.selectedStage.getId()?
		$scope.spinnerOn = true

		console.log 'retrieving lines...'
		rpc 'buildConsoles', 'read', 'getLines', id: $scope.selectedStage.getId(), (error, lines) ->
			$scope.spinnerOn = false

			for lineNumber, lineText of lines
				addLine lineNumber, lineText

	handleExportUrisAdded = (data) ->
		$scope.exportUris ?= []
		$scope.exportUris = $scope.exportUris.concat data.uris

	addLine = (lineNumber, lineText) ->
		$scope.lines[lineNumber-1] = lineText

	handleLinesAdded = (data) ->
		$scope.lines ?= []
		for lineNumber, lineText of data
			addLine lineNumber, lineText

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

		if $scope.selectedStage.getId()?
			addedLineEvents = events('buildConsoles', 'new output', $scope.selectedStage.getId()).setCallback(handleLinesAdded).subscribe()
	$scope.$on '$destroy', () -> addedLineEvents.unsubscribe() if addedLineEvents?

	$scope.$watch 'selectedChange.getId()', (newValue, oldValue) ->
		updateExportUrisAddedListener()
		retrieveCurrentChangeExportUris()

	$scope.$watch 'selectedStage.getId()', (newValue, oldValue) ->
		updateAddedLineListener()
		retrieveLines()
]
