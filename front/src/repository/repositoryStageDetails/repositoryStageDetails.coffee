'use strict'

window.RepositoryStageDetails = ['$scope', '$location', 'rpc', 'events', ($scope, $location, rpc, events) ->
	updateUrl = () ->
		$scope.currentUrl = $location.absUrl()
	$scope.$on '$routeUpdate', updateUrl
	updateUrl()

	retrieveCurrentChangeExportUris = () ->
		$scope.exportUris = []
		return if not $scope.currentChangeId?

		rpc 'changes', 'read', 'getChangeExportUris', id: $scope.currentChangeId, (error, uris) ->
			$scope.exportUris = uris

	retrieveLines = () ->
		$scope.lines = []
		return if not $scope.currentStageId?
		$scope.spinnerOn = true

		rpc 'buildConsoles', 'read', 'getLines', id: $scope.currentStageId, (error, lines) ->
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

		if $scope.currentChangeId?
			addedExportUrisEvents = events('changes', 'export uris added', $scope.currentChangeId).setCallback(handleExportUrisAdded).subscribe()
	$scope.$on '$destroy', () -> addedExportUrisEvents.unsubscribe() if addedExportUrisEvents?

	addedLineEvents = null
	updateAddedLineListener = () ->
		if addedLineEvents?
			addedLineEvents.unsubscribe()
			addedLineEvents = null

		if $scope.currentStageId?
			addedLineEvents = events('buildConsoles', 'new output', $scope.currentStageId).setCallback(handleLinesAdded).subscribe()
	$scope.$on '$destroy', () -> addedLineEvents.unsubscribe() if addedLineEvents?

	$scope.$watch 'currentChangeId', (newValue, oldValue) ->
		updateExportUrisAddedListener()
		retrieveCurrentChangeExportUris()

	$scope.$watch 'currentStageId', (newValue, oldValue) ->
		updateAddedLineListener()
		retrieveLines()
]
