'use strict'

window.RepositoryStageDetails = ['$scope', '$location', 'rpc', 'events', 'xmlParser', 'integerConverter', 'currentRepository', 'currentChange', 'currentStage', ($scope, $location, rpc, events, xmlParser, integerConverter, currentRepository, currentChange, currentStage) ->
	$scope.selectedRepository = currentRepository
	$scope.selectedChange = currentChange
	$scope.selectedStage = currentStage

	$scope.lines = null
	$scope.linesCache = {}

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

		$scope.lines = null
		return if not $scope.selectedStage.getId()?
		
		$scope.spinnerOn = true
		rpc 'buildConsoles', 'read', 'getLines', id: $scope.selectedStage.getId(), (error, lines) ->
			$scope.spinnerOn = false
			processLines lines

			# $scope.lines ?= []
			# for lineNumber, lineText of lines
			# 	addLine lineNumber, lineText

	retrieveJUnitOutput = () ->
		assert.ok $scope.outputType is 'junit'

		$scope.lines = []
		$scope.linesCache = {}
		return if not $scope.selectedStage.getId()?

		$scope.spinnerOn = true
		rpc 'buildConsoles', 'read', 'getJUnit', id: $scope.selectedStage.getId(), (error, junitOutputs) ->
			$scope.spinnerOn = false

			getArrayOfTestSuites = () ->
				testSuites = []
				for junitOutput in junitOutputs
					parsed = xmlParser.parse junitOutput
					parsedTestSuites = if parsed.testsuites then parsed.testsuites.testsuite else parsed.testsuite

					if parsedTestSuites instanceof Array
						testSuites = testSuites.concat parsedTestSuites
					else
						testSuites.push parsedTestSuites

				return testSuites

			getAllSanitizedTestCases = (testSuites) ->
				sanitizeTestCase = (testCase) ->
					name: testCase.__name
					time: testCase.__time
					status: if testCase.failure? or testCase['system-err']? then 'failed' else 'passed'
					failure: testCase.failure?.text if testCase.failure?.text?
					error: testCase['system-err'] if testCase['system-err']?

				testCases = []
				for testSuite in testSuites
					if testSuite.testcase instanceof Array
						testCases = testCases.concat (sanitizeTestCase testCase for testCase in testSuite.testcase)
					else
						testCases.push sanitizeTestCase testSuite.testcase

				return testCases

			testSuites = getArrayOfTestSuites()
			testCases = getAllSanitizedTestCases testSuites
			$scope.junit = testCases

	handleExportUrisAdded = (data) ->
		$scope.exportUris ?= []
		$scope.exportUris = $scope.exportUris.concat data.uris

	# addLine = (lineNumber, lineText) ->
	# 	$scope.lines[lineNumber-1] = lineText

	handleLinesAdded = (data) ->
		# $scope.lines ?= []
		# for lineNumber, lineText of data
		# 	addLine lineNumber, lineText

		processLines data

	processLines = (lines) ->
		$scope.lines ?= []
		$scope.linesCache ?= {}
		for lineNumber, lineText of lines
			lineNumber = integerConverter.toInteger lineNumber

			if $scope.linesCache[lineNumber]?
				$scope.linesCache[lineNumber].text = lineText
			else
				lineToAdd = 
					number: lineNumber
					text: lineText
				$scope.lines.push lineToAdd
				$scope.linesCache[lineNumber] = lineToAdd

	clearOutput = () ->
		$scope.outputType = null
		$scope.lines = []
		$scope.linesCache = {}
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
