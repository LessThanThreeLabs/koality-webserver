window.D3ChangesLineGraph = {}

window.D3ChangesLineGraph.create = (element) ->
	d3ChangesLineGraph = new @clazz element
	d3ChangesLineGraph.initialize()
	return d3ChangesLineGraph

window.D3ChangesLineGraph.clazz = class D3ChangesLineGraph
	PADDING: {top: 10, left: 50, right: 20, bottom: 50}
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
				.y((d) -> return y d)

		previouslyNoData = not path.datum()?

		path = path.datum(data)
		if previouslyNoData or startFromZero
			path = path.attr 'd', computeChangeLine x, (value) -> return y 0
		path = path.transition().duration(transitionTime)
		path = path.attr('d', computeChangeLine x, y)

	drawGraph: (d3Binner, startFromZero) ->
		console.log 'drawing graph...'

		allIntervals = d3Binner.getAllIntervals()
		histograms = d3Binner.getHistograms()

		x = d3.time.scale()
			.domain([allIntervals[0], allIntervals[allIntervals.length-1]])
			.range([@PADDING.left+@AXIS_BUFFER, @element.width()-@PADDING.right])
		y = d3.scale.linear()
			.domain([0, 100])
			.range([@element.height()-@PADDING.bottom-@AXIS_BUFFER, @PADDING.top])

		@_updatePath @allLine, histograms.all, x, y, allIntervals, startFromZero, 500
		@_updatePath @passedLine, histograms.passed, x, y, allIntervals, startFromZero, 750
		@_updatePath @failedLine, histograms.failed, x, y, allIntervals, startFromZero, 1000

		xAxis = d3.svg.axis().scale(x).ticks(20).tickFormat(d3.time.format '%m/%d').orient 'bottom'
		yAxis = d3.svg.axis().scale(y).ticks(10).orient 'left'

		@xAxisLabel.call xAxis
		@yAxisLabel.call yAxis
