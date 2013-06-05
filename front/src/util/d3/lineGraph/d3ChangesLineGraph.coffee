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

		@svg = d3.select(@element[0]).select('svg').append 'g'

		@xAxisLabel = @svg.append('g').attr('class', 'xAxis').attr 'transform', "translate(0, #{@element.height()-@PADDING.bottom})"
		@yAxisLabel = @svg.append('g').attr('class', 'yAxis').attr 'transform', "translate(#{@PADDING.left}, 0)"

		@xReferenceLines = @svg.append('g').attr 'class', 'xReferenceLines'
		@yReferenceLines = @svg.append('g').attr 'class', 'yReferenceLines'

		@allLine = @svg.append('path').attr 'class', 'allLine'
		@passedLine = @svg.append('path').attr 'class', 'passedLine'
		@failedLine = @svg.append('path').attr 'class', 'failedLine'

		@allLineDots = @svg.append('g').attr 'class', 'allLineDots'
		@passedLineDots = @svg.append('g').attr 'class', 'passedLineDots'
		@failedLineDots = @svg.append('g').attr 'class', 'failedLineDots'

		@allTooltip = d3.select(@element[0]).append('xhtml:div')
			.html('<span class="prettyTooltip">hello</span>')
			.attr 'class', 'allTooltip'
		@passedTooltip = d3.select(@element[0]).append('xhtml:div')
			.html('<span class="prettyTooltip">hello</span>')
			.attr 'class', 'passedTooltip'
		@failedTooltip = d3.select(@element[0]).append('xhtml:div')
			.html('<span class="prettyTooltip">hello</span>')
			.attr 'class', 'failedTooltip'

	_updatePath: (path, data, x, y, allIntervals, startFromZero, transitionTime) =>
		computeChangeLine = (x, y) ->
			return d3.svg.line()
				.defined((d) -> return not isNaN d)
				.x((d, index) -> return x allIntervals[index])
				.y((d) -> return y d)

		path.attr 'display', 'inline'

		previouslyNoData = not path.datum()?
		path = path.datum(data)
		if previouslyNoData or startFromZero
			path = path.attr 'd', computeChangeLine x, ((d) -> return y 0)
		path = path.transition().duration(transitionTime)
		path = path.attr('d', computeChangeLine x, y)

	_hidePath: (path, dots) =>
		path.attr 'display', 'none'

	_updateDots: (dots, tooltip, tooltipTextGenerator, data, x, y, allIntervals) =>
		dots.selectAll('circle').remove()
		newDots = dots.selectAll('circle').data(data)
		newDots.enter()
			.append('circle')
			.attr('class', 'smallDot')
			.attr('cx', (d, index) -> return x allIntervals[index])
			.attr('cy', (d) -> return if isNaN d then 0 else y d)
			.attr('r', (d) -> return if isNaN d then 0 else 1.5)
		newDots.enter()
			.append('circle')
			.attr('class', 'largeDot')
			.attr('cx', (d, index) -> return x allIntervals[index])
			.attr('cy', (d) -> return if isNaN d then 0 else y d)
			.attr('r', (d) -> return if isNaN d then 0 else 5.0)
			.on('mouseover', (d, index) =>
				tooltip
					.style('left', (x(allIntervals[index]) - 130) + 'px')
					.style('top', if isNaN d then '0' else (y(d) - 50) + 'px')
					.classed('visible', true)
				tooltip.select('.prettyTooltip').html tooltipTextGenerator allIntervals[index], allIntervals[index+1], d
			)
			.on('mouseout', (d, index) =>
				tooltip.classed('visible', false)
			)
		newDots.exit()
			.remove()

	_hideDots: (dots) =>
		dots.selectAll('circle').remove()

	_getTooltipTextGenerator: (d3Binner, changeType, isPercentage) =>
		return (firstDate, secondDate, value) ->
			getFirstLine = () ->
				secondDate ?= d3Binner.getTimeInterval().end
				if d3Binner.getIntervalName() is 'hour'
					return d3.time.format('%a %m/%d, %I:%M')(firstDate) + ' to ' + d3.time.format('%I:%M %p')(secondDate)
				else
					return d3.time.format('%a %m/%d')(firstDate) + ' to ' + d3.time.format('%a %m/%d')(secondDate)

			getSecondLine = () ->
				changeTag = if changeType is 'all' then 'total' else changeType
				if isPercentage then return d3.format('.0%')(value) + ' of changes ' + changeTag
				else return value + ' changes ' + changeTag

			return getFirstLine() + '<br>' + getSecondLine()

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

		@_updatePath @allLine, histograms.all, x, y, allIntervals, startFromZero, 500
		@_updateDots @allLineDots, @allTooltip, @_getTooltipTextGenerator(d3Binner, 'all', false), histograms.all, x, y, allIntervals

		@_updatePath @passedLine, histograms.passed, x, y, allIntervals, startFromZero, 750
		@_updateDots @passedLineDots, @passedTooltip, @_getTooltipTextGenerator(d3Binner, 'passed', false), histograms.passed, x, y, allIntervals

		@_updatePath @failedLine, histograms.failed, x, y, allIntervals, startFromZero, 1000
		@_updateDots @failedLineDots, @failedTooltip, @_getTooltipTextGenerator(d3Binner, 'failed', false), histograms.failed, x, y, allIntervals

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

		@_hidePath @allLine
		@_hideDots @allLineDots

		if changeType is 'passed'
			@_hidePath @failedLine
			@_hideDots @failedLineDots

			@_updatePath @passedLine, percentageHistograms.passed, x, y, allIntervals, startFromZero, 750
			@_updateDots @passedLineDots, @passedTooltip, @_getTooltipTextGenerator(d3Binner, 'passed', true), percentageHistograms.passed, x, y, allIntervals

		if changeType is 'failed'
			@_hidePath @passedLine
			@_hideDots @passedLineDots

			@_updatePath @failedLine, percentageHistograms.failed, x, y, allIntervals, startFromZero, 750
			@_updateDots @failedLineDots, @failedTooltip, @_getTooltipTextGenerator(d3Binner, 'failed', true), percentageHistograms.failed, x, y, allIntervals

		@_updateAxisLabels d3Binner, x, y, true
