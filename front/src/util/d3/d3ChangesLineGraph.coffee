window.D3ChangesLineGraph = {}

window.D3ChangesLineGraph.create = (element) ->
	d3ChangesLineGraph = new @clazz element
	d3ChangesLineGraph.initialize()
	return d3ChangesLineGraph

window.D3ChangesLineGraph.clazz = class D3ChangesLineGraph
	PADDING: {top: 10, left: 35, right: 10, bottom: 25}
	AXIS_BUFFER: 10

	constructor: (@element) ->
		assert.ok @element? and typeof @element is 'object'

	initialize: () =>
		@bounds =
			top: @PADDING.top
			left: @PADDING.left + @AXIS_BUFFER
			right: @element.width() - @PADDING.right
			bottom: @element.height() - @PADDING.bottom - @AXIS_BUFFER

		@svg = d3.select(@element[0]).append 'g'

		@xAxisLabel = @svg.append('g').attr('class', 'xAxis').attr 'transform', "translate(0, #{@element.height()-@PADDING.bottom})"
		@yAxisLabel = @svg.append('g').attr('class', 'yAxis').attr 'transform', "translate(#{@PADDING.left}, 0)"

		@xReferenceLines = @svg.append('g').attr 'class', 'xReferenceLines'
		@yReferenceLines = @svg.append('g').attr 'class', 'yReferenceLines'

		@allLine = @svg.append('path').attr 'class', 'allLine'
		@passedLine = @svg.append('path').attr 'class', 'passedLine'
		@failedLine = @svg.append('path').attr 'class', 'failedLine'

	_updatePath: (path, data, x, y, allIntervals, startFromZero, transitionTime) =>
		computeChangeLine = (x, y) ->
			return d3.svg.line()
				.defined((d) -> return not isNaN d)
				.x((d, index) -> return x allIntervals[index])
				.y((d) -> return y d)

		previouslyNoData = not path.datum()?

		path = path.datum(data)
		if previouslyNoData or startFromZero
			path = path.attr 'd', computeChangeLine x, ((d) -> return y 0)
		path = path.transition().duration(transitionTime)
		path = path.attr('d', computeChangeLine x, y)

	_updateAxisLabels: (d3Binner, x, y, showYAsPercent=false) =>
		getTimeFormat = () ->
			timeInDay = 60 * 60 * 24 * 1000
			startTime = d3Binner.getTimeInterval().start
			endTime = d3Binner.getTimeInterval().end

			hourFormatter = (date) ->
				am = date.getHours() < 12
				hour = date.getHours() % 12
				hour = 12 if hour is 0
				return hour + if am then 'a' else 'p'

			if endTime - startTime <= timeInDay
				return {format: hourFormatter, ticks: 24, subdivide: 0}
			else if endTime - startTime <= 7 * timeInDay
				subdivide = if d3Binner.getIntervalName() is 'hour' then 3 else 0
				return {format: d3.time.format('%a'), ticks: 7, subdivide:  subdivide}
			else if endTime - startTime <= 30 * timeInDay
				ticks = if d3Binner.getIntervalName() is 'day' then 5 else 4
				subdivide = if d3Binner.getIntervalName() is 'day' then 6 else 0
				return {format: d3.time.format('%m/%d'), ticks: ticks, subdivide: subdivide}
			else
				return {format: d3.time.format('%b'), ticks: 12, subdivide: 0}

		addXReferenceLines = () =>
			@xReferenceLines.selectAll('line').remove()
			
			data = x.ticks(timeFormat.ticks)
				.filter (tick) => return x(tick) - @bounds.left > 10 and @bounds.right - x(tick) > 10

			lines = @xReferenceLines.selectAll('line')
				.data(data)
			lines.enter()
				.append('line')
				.attr('x1', x)
				.attr('x2', x)
				.attr('y1', @bounds.bottom)
				.attr('y2', @bounds.top)
			lines.exit()
				.remove()

		addYReferenceLines = () =>
			@yReferenceLines.selectAll('line').remove()
			
			lines = @yReferenceLines.selectAll('line')
				.data(y.ticks(5))
			lines.enter()
				.append('line')
				.attr('x1', @bounds.left)
				.attr('x2', @bounds.right)
				.attr('y1', y)
				.attr('y2', y)
			lines.exit()
				.remove()

		timeFormat = getTimeFormat()
		xAxis = d3.svg.axis().scale(x)
			.ticks(timeFormat.ticks)
			.tickSubdivide(timeFormat.subdivide)
			.tickFormat(timeFormat.format)
			.orient 'bottom'
		yAxis = d3.svg.axis().scale(y).ticks(10).orient 'left'
		yAxis.tickFormat d3.format '.0%' if showYAsPercent

		@xAxisLabel.call xAxis
		@yAxisLabel.call yAxis

		addXReferenceLines()
		addYReferenceLines()

	drawGraph: (d3Binner, startFromZero) =>
		assert.ok d3Binner? and typeof d3Binner is 'object'

		allIntervals = d3Binner.getAllIntervals()
		histograms = d3Binner.getHistograms()

		x = d3.time.scale()
			.domain([allIntervals[0], allIntervals[allIntervals.length-1]])
			.range([@bounds.left, @bounds.right])
		y = d3.scale.linear()
			.domain([0, d3.max histograms.all])
			.range([@bounds.bottom, @bounds.top])

		@allLine.attr 'display', 'inline'
		@passedLine.attr 'display', 'inline'
		@failedLine.attr 'display', 'inline'

		@_updatePath @allLine, histograms.all, x, y, allIntervals, startFromZero, 500
		@_updatePath @passedLine, histograms.passed, x, y, allIntervals, startFromZero, 750
		@_updatePath @failedLine, histograms.failed, x, y, allIntervals, startFromZero, 1000

		@_updateAxisLabels d3Binner, x, y

	drawPercentageGraph: (d3Binner, changeType, startFromZero=true) =>
		assert.ok d3Binner? and typeof d3Binner is 'object'
		assert.ok changeType? and changeType is 'passed' or changeType is 'failed'

		percentageHistograms = d3Binner.getPercentageHistograms()
		allIntervals = d3Binner.getAllIntervals()

		# We remove intervals that belong to NaN values so the
		# graph smoothes itself out, except for the endpoints
		fixHistogramAndIntervals = () ->
			isValidHistogramValue = (histogram) ->
				return (value, index) ->
					return true if index is 0 or index is histogram.length - 1
					return not isNaN value

			allIntervals = allIntervals.filter (interval, index) ->
				return true if index is 0 or index is allIntervals.length - 1
				if changeType is 'passed' then return not isNaN percentageHistograms.passed[index]
				if changeType is 'failed' then return not isNaN percentageHistograms.failed[index]

			percentageHistograms.passed = percentageHistograms.passed.filter isValidHistogramValue percentageHistograms.passed
			percentageHistograms.failed = percentageHistograms.failed.filter isValidHistogramValue percentageHistograms.failed

		fixHistogramAndIntervals()

		x = d3.time.scale()
			.domain([allIntervals[0], allIntervals[allIntervals.length-1]])
			.range([@bounds.left, @bounds.right])
		y = d3.scale.linear()
			.domain([0, 1])
			.range([@bounds.bottom, @bounds.top])

		@allLine.attr 'display', 'none'

		if changeType is 'passed'
			@passedLine.attr 'display', 'inline'
			@failedLine.attr 'display', 'none'
			@_updatePath @passedLine, percentageHistograms.passed, x, y, allIntervals, startFromZero, 750

		if changeType is 'failed'
			@passedLine.attr 'display', 'none'
			@failedLine.attr 'display', 'inline'
			@_updatePath @failedLine, percentageHistograms.failed, x, y, allIntervals, startFromZero, 750

		@_updateAxisLabels d3Binner, x, y, true
