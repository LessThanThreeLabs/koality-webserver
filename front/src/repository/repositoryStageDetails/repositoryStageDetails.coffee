'use strict'

window.RepositoryStageDetails = ['$scope', '$location', 'rpc', 'events', 'currentRepository', 'currentChange', 'currentStage', ($scope, $location, rpc, events, currentRepository, currentChange, currentStage) ->
# 	$scope.selectedRepository = currentRepository
# 	$scope.selectedChange = currentChange
# 	$scope.selectedStage = currentStage

# 	updateUrl = () ->
# 		$scope.currentUrl = $location.absUrl()
# 	$scope.$on '$routeUpdate', updateUrl
# 	updateUrl()

# 	retrieveCurrentChangeExportUris = () ->
# 		$scope.exportUris = []
# 		return if not $scope.selectedChange.getId()?

# 		rpc 'changes', 'read', 'getChangeExportUris', id: $scope.selectedChange.getId(), (error, uris) ->
# 			$scope.exportUris = uris

# 	retrieveLines = () ->
# 		$scope.lines = null
# 		return if not $scope.selectedStage.getId()?
		
# 		$scope.spinnerOn = true

# 		rpc 'buildConsoles', 'read', 'getLines', id: $scope.selectedStage.getId(), (error, lines) ->
# 			$scope.spinnerOn = false

# 			$scope.lines ?= []
# 			for lineNumber, lineText of lines
# 				addLine lineNumber, lineText

# 	retrieveJUnitOutput = () ->
# 		$scope.lines = null
# 		return if not $scope.selectedStage.getId()?

# 		$scope.spinnerOn = true

# 		setTimeout (() ->
# 			$scope.spinnerOn = false

# 			$scope.junitOutput = ['<?xml version="1.0" encoding="UTF-8" ?>
# <testsuites>
# <testsuite name="accountInformationValidator" errors="0" tests="6" failures="0" time="0.002" timestamp="2013-08-14T16:12:10">
#   <testcase classname="accountInformationValidator" name="should correctly check email validity" time="0.001"></testcase>
#   <testcase classname="accountInformationValidator" name="should correctly check password validity" time="0"></testcase>
#   <testcase classname="accountInformationValidator" name="should correctly check first name validity" time="0.001"></testcase>
#   <testcase classname="accountInformationValidator" name="should correctly check last name validity" time="0"></testcase>
#   <testcase classname="accountInformationValidator" name="should correctly check ssh alias validity" time="0"></testcase>
#   <testcase classname="accountInformationValidator" name="should correctly check ssh key validity" time="0"></testcase>
# </testsuite>
# </testsuites>']
# 		), 500

# 	handleExportUrisAdded = (data) ->
# 		$scope.exportUris ?= []
# 		$scope.exportUris = $scope.exportUris.concat data.uris

# 	addLine = (lineNumber, lineText) ->
# 		$scope.lines[lineNumber-1] = lineText

# 	handleLinesAdded = (data) ->
# 		$scope.lines ?= []
# 		for lineNumber, lineText of data
# 			addLine lineNumber, lineText

# 	clearOutput = () ->
# 		$scope.lines = null
# 		$scope.junitOutput = null

# 	addedExportUrisEvents = null
# 	updateExportUrisAddedListener = () ->
# 		if addedExportUrisEvents?
# 			addedExportUrisEvents.unsubscribe()
# 			addedExportUrisEvents = null

# 		if $scope.selectedChange.getId()?
# 			addedExportUrisEvents = events('changes', 'export uris added', $scope.selectedChange.getId()).setCallback(handleExportUrisAdded).subscribe()
# 	$scope.$on '$destroy', () -> addedExportUrisEvents.unsubscribe() if addedExportUrisEvents?

# 	addedLineEvents = null
# 	updateAddedLineListener = () ->
# 		if addedLineEvents?
# 			addedLineEvents.unsubscribe()
# 			addedLineEvents = null

# 		if $scope.selectedStage.getId()?
# 			addedLineEvents = events('buildConsoles', 'new output', $scope.selectedStage.getId()).setCallback(handleLinesAdded).subscribe()
# 	$scope.$on '$destroy', () -> addedLineEvents.unsubscribe() if addedLineEvents?

# 	$scope.selectOutputType = (outputType) =>
# 		$scope.outputType = outputType

# 		if outputType is 'lines' and not $scope.lines? then retrieveLines()
# 		if outputType is 'junit' and not $scope.junitOutput? then retrieveJUnitOutput()

# 	$scope.$watch 'selectedChange.getId()', (newValue, oldValue) ->
# 		updateExportUrisAddedListener()
# 		retrieveCurrentChangeExportUris()

# 	$scope.$watch 'selectedStage.getId()', (newValue, oldValue) ->
# 		updateAddedLineListener()
# 		clearOutput()

# 	$scope.$watch 'selectedStage.getInformation().hasJUnit', (hasJUnit) ->
# 		if hasJUnit
# 			$scope.outputType = 'junit'
# 			retrieveJUnitOutput()
# 		else 
# 			$scope.outputType = 'lines'
# 			retrieveLines()
]
