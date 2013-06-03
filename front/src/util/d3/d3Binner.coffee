window.D3Binner = {}

window.D3Binner.create = (changes, changesToTrack, startTime, endTime, intervalName) ->
	d3Binner = new @clazz changes, changesToTrack, startTime, endTime, intervalName
	d3Binner.initialize()
	return d3Binner

window.D3Binner.clazz = class D3Binner
	constructor: (@changes, @changesToTrack, @startTime, @endTime, @intervalName) ->
		assert.ok @changes? and typeof @changes is 'object'
		assert.ok @changesToTrack? and typeof @changesToTrack is 'string'
		assert.ok @changesToTrack is 'all' or @changesToTrack is 'passed' or @changesToTrack is 'failed'
		assert.ok @startTime? and typeof @startTime is 'object'
		assert.ok @endTime? and typeof @endTime is 'object'
		assert.ok @intervalName? and typeof @intervalName is 'string'

	initialize: () =>
		@interval = @_getD3TimeInterval()
		@allIntervals = @interval.range @interval.floor(@startTime), @interval.ceil(@endTime)
		@binner = @_getBinner()

	_getBinner: () =>
		binner = d3.time.scale()
			.domain([@allIntervals[0], @allIntervals[@allIntervals.length - 1]])
			.range([0, @allIntervals.length - 1])
			.interpolate(d3.interpolateRound)

	_getD3TimeInterval: () =>
		switch @intervalName
			when 'hour' then return d3.time.hour
			when 'day' then return d3.time.day
			when 'week' then return d3.time.week
			when 'month' then return d3.time.month
			else throw 'invalid interval'

	getHistograms: () =>
		allHistogram = (0 for index in [0...@allIntervals.length])
		passedHistogram = (0 for index in [0...@allIntervals.length])
		failedHistogram = (0 for index in [0...@allIntervals.length])

		for change in @changes
			assert change.endTime?
			index = @binner @interval.floor new Date(change.endTime)

			allHistogram[index]++
			if change.status is 'passed' then passedHistogram[index]++
			if change.status is 'failed' then failedHistogram[index]++

		histograms =
			all: allHistogram if @changesToTrack is 'all'
			passed: passedHistogram if @changesToTrack is 'all' or @changesToTrack is 'passed'
			failed: failedHistogram if @changesToTrack is 'all' or @changesToTrack is 'failed'
		return histograms

	getPercentageHistograms: () =>
		histograms = @getHistograms()

		maxValue = d3.max [d3.max(histograms.all ? []), d3.max(histograms.passed ? []), d3.max(histograms.failed ? [])]
		return histograms if maxValue is 0

		if histograms.all? then histograms.all = histograms.all.map (histogramValue) -> return histogramValue / maxValue
		if histograms.passed? then histograms.passed = histograms.passed.map (histogramValue) -> return histogramValue / maxValue
		if histograms.failed? then histograms.failed = histograms.failed.map (histogramValue) -> return histogramValue / maxValue

		return histograms

	getTimeInterval: () =>
		return {start: @startTime, end: @endTime}

	getAllIntervals: () =>
		return @allIntervals

	getIntervalName: () =>
		return @intervalName
