'use strict'

window.Analytics = ['$scope', 'rpc', 'events', ($scope, rpc, events) ->
	allRepository = {id: -1, name: 'All'}

	allowedIntervals =
		hour: {value: 'hour', title: 'Hours'}
		day: {value: 'day', title: 'Days'}
		week: {value: 'week', title: 'Weeks'}
		month: {value: 'month', title: 'Months'}

	$scope.options = 
		graph: 'passedAndFailed'
		repository: allRepository.id
		repositories: [allRepository]
		duration: 'last7'
		interval: 'hour'
		mode: 'line'

	$scope.graphOptions =
		changes: []
		start: new Date()
		end: new Date()
		interval: 'hour'

	setGraphBounds = () ->
		getMidnightOfDateDelta = (dateDelta) ->
			midnightToday = new Date((new Date()).setHours(0, 0, 0, 0))
			return new Date(midnightToday.setDate(midnightToday.getDate() + dateDelta))

		if $scope.options.duration is 'today'
			$scope.graphOptions.start = getMidnightOfDateDelta 0
			$scope.graphOptions.end = getMidnightOfDateDelta 1

		if $scope.options.duration is 'yesterday'
			$scope.graphOptions.start = getMidnightOfDateDelta -1
			$scope.graphOptions.end = getMidnightOfDateDelta 0

		if $scope.options.duration is 'last7'
			$scope.graphOptions.start = getMidnightOfDateDelta -7
			$scope.graphOptions.end = getMidnightOfDateDelta 0

		if $scope.options.duration is 'last30'
			$scope.graphOptions.start = getMidnightOfDateDelta -30
			$scope.graphOptions.end = getMidnightOfDateDelta 0

		if $scope.options.duration is 'last365'
			$scope.graphOptions.start = getMidnightOfDateDelta -365
			$scope.graphOptions.end = getMidnightOfDateDelta 0

	updateAllowedIntervals = () ->
		if $scope.options.duration is 'today' then $scope.options.intervals = [allowedIntervals.hour]
		if $scope.options.duration is 'yesterday' then $scope.options.intervals = [allowedIntervals.hour]
		if $scope.options.duration is 'last7' then $scope.options.intervals = [allowedIntervals.hour, allowedIntervals.day]
		if $scope.options.duration is 'last30' then $scope.options.intervals = [allowedIntervals.day, allowedIntervals.week]
		if $scope.options.duration is 'last365' then $scope.options.intervals = [allowedIntervals.day, allowedIntervals.week, allowedIntervals.month]

		matchingInterval = $scope.options.intervals.some (interval) -> return interval.value is $scope.options.interval
		$scope.options.interval = $scope.options.intervals[0].value if not matchingInterval

	getRepositories = () ->
		rpc.makeRequest 'repositories', 'read', 'getRepositories', null, (error, repositories) ->
			$scope.$apply () ->
				$scope.options.repositories = [allRepository].concat repositories
				getChanges()

	getChanges = () ->
		return if $scope.options.repositories.every (repository) -> return repository.id < 0

		getRepositoriesToRequest = () ->
			if $scope.options.repository >= 0 then return [$scope.options.repository]
			else
				return $scope.options.repositories
					.map((repository) -> return repository.id)
					.filter((repositoryId) -> repositoryId >= 0)

		$scope.graphOptions.changes = []

		console.log 'requesting changes...'
		requestParams =
			repositories: getRepositoriesToRequest()
			startTimestamp: $scope.graphOptions.start.getTime()
			endTimestamp: $scope.graphOptions.end.getTime()
		rpc.makeRequest 'changes', 'read', 'getChangesBetweenTimestamps', requestParams, (error, changes) ->
			$scope.$apply () ->
				# $scope.graphOptions.changes = changes
				$scope.graphOptions.changes = (generateRandomChange requestParams.startTimestamp, requestParams.endTimestamp for index in [0..10000])

		generateRandomChange = (startTimestamp, endTimestamp) ->
			status: if Math.random() < .75 then 'passed' else 'failed'
			endTime: Math.random() * (endTimestamp - startTimestamp) + startTimestamp

	getRepositories()

	$scope.$watch 'options.repository', () -> 
		getChanges()

	$scope.$watch 'options.duration', () ->
		updateAllowedIntervals()
		setGraphBounds()
		getChanges()

	$scope.$watch 'options.interval', () ->
		$scope.graphOptions.interval = $scope.options.interval

]