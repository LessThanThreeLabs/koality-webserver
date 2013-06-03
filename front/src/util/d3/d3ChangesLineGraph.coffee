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
		@svg = d3.select(@element[0]).append 'g'

		@allLine = @svg.append('path').attr 'class', 'allLine'
		@passedLine = @svg.append('path').attr 'class', 'passedLine'
		@failedLine = @svg.append('path').attr 'class', 'failedLine'

		@xAxisLabel = @svg.append('g').attr('class', 'xAxis').attr 'transform', "translate(0, #{@element.height()-@PADDING.bottom})"
		@yAxisLabel = @svg.append('g').attr('class', 'yAxis').attr 'transform', "translate(#{@PADDING.left}, 0)"

	_updatePath: (path, data, x, y, allIntervals, startFromZero, transitionTime) =>
		computeChangeLine = (x, y) ->
			return d3.svg.line()
				.x((d, index) -> return x allIntervals[index])
				.y((d) -> return y d * 100)

		previouslyNoData = not path.datum()?

		path = path.datum(data)
		if previouslyNoData or startFromZero
			path = path.attr 'd', computeChangeLine x, (value) -> return y 0
		path = path.transition().duration(transitionTime)
		path = path.attr('d', computeChangeLine x, y)

	_updateAxisLabels: (d3Binner, x, y) ->
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
				ticks = if d3Binner.getIntervalName() is 'day' then 15 else 4
				subdivide = if d3Binner.getIntervalName() is 'day' then 1 else 0
				return {format: d3.time.format('%m/%d'), ticks: ticks, subdivide: subdivide}
			else
				return {format: d3.time.format('%b'), ticks: 12, subdivide: 0}

		timeFormat = getTimeFormat()
		xAxis = d3.svg.axis().scale(x)
			.ticks(timeFormat.ticks)
			.tickSubdivide(timeFormat.subdivide)
			.tickFormat(timeFormat.format)
			.orient 'bottom'
		yAxis = d3.svg.axis().scale(y).ticks(10).orient 'left'

		@xAxisLabel.call xAxis
		@yAxisLabel.call yAxis

	drawGraph: (d3Binner, startFromZero) ->
		console.log 'drawing graph...'
		console.log d3Binner.changes

		allIntervals = d3Binner.getAllIntervals()
		histograms = d3Binner.getPercentageHistograms()

		x = d3.time.scale()
			.domain([allIntervals[0], allIntervals[allIntervals.length-1]])
			.range([@PADDING.left+@AXIS_BUFFER, @element.width()-@PADDING.right])
		y = d3.scale.linear()
			.domain([0, 100])
			.range([@element.height()-@PADDING.bottom-@AXIS_BUFFER, @PADDING.top])

		@allLine.attr 'display', if histograms.all? then 'inline' else 'none'
		@passedLine.attr 'display', if histograms.passed? then 'inline' else 'none'
		@failedLine.attr 'display', if histograms.failed? then 'inline' else 'none'

		@_updatePath @allLine, histograms.all, x, y, allIntervals, startFromZero, 500 if histograms.all?
		@_updatePath @passedLine, histograms.passed, x, y, allIntervals, startFromZero, 750  if histograms.passed?
		@_updatePath @failedLine, histograms.failed, x, y, allIntervals, startFromZero, 1000  if histograms.failed?

		@_updateAxisLabels d3Binner, x, y
