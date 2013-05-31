'use strict'

angular.module('koality.d3.directive', []).
	directive('changeAnalytics', ['$window', ($window) ->
		restrict: 'E'
		replace: true
		scope: 
			changes: '='
			duration: '='
			interval: '='
		template: '<svg class="changeAnalytics" xmlns="http://www.w3.org/2000/svg" version="1.1"></svg>'
		link: (scope, element, attributes) ->
			padding = {top: 10, left: 50, right: 20, bottom: 50}
			width = element.width()
			height = element.height()
			axisBuffer = 10
			lineTransitionTime = 1500

			svg = d3.select(element[0]).append 'g'

			allLine = svg.append('path').attr 'class', 'allLine'
			passedLine = svg.append('path').attr 'class', 'passedLine'
			failedLine = svg.append('path').attr 'class', 'failedLine'

			xAxisLabel = svg.append('g').attr('class', 'xAxis').attr 'transform', "translate(0, #{height-padding.bottom})"
			yAxisLabel = svg.append('g').attr('class', 'yAxis').attr 'transform', "translate(#{padding.left}, 0)"

			updatePath = (path, data, x, y, allIntervals, transitionTime) ->
				computeChangeLine = (x, y, allIntervals) ->
					return d3.svg.line()
						.x((d, index) -> return x allIntervals[index])
						.y((d) -> return y d)

				alreadyContainsData = path.datum()?

				path = path.datum(data)

				if not alreadyContainsData
					yStart = (value) -> return y 0
					path = path.attr 'd', computeChangeLine x, yStart, allIntervals

				path = path.transition().duration(transitionTime)
				path = path.attr('d', computeChangeLine x, y, allIntervals)

			getInterval = () ->
				switch scope.interval
					when 'hour' then return d3.time.hour
					when 'day' then return d3.time.day
					when 'week' then return d3.time.week
					when 'month' then return d3.time.month
					else throw 'invalid interval'

			getBinner = (allIntervals) ->
				binner = d3.time.scale()
					.domain([allIntervals[0], allIntervals[allIntervals.length - 1]])
					.range([0, allIntervals.length - 1])
					.interpolate(d3.interpolateRound)

			getHistograms = (binner, interval, allIntervals) ->
				allHistogram = (0 for index in [0...allIntervals.length])
				passedHistogram = (0 for index in [0...allIntervals.length])
				failedHistogram = (0 for index in [0...allIntervals.length])

				for change in scope.changes
					index = binner interval.floor new Date(change.endTime)
					allHistogram[index]++
					if change.status is 'passed' then passedHistogram[index]++
					if change.status is 'failed' then failedHistogram[index]++

				histograms =
					all: allHistogram
					passed: passedHistogram
					failed: failedHistogram
				return histograms

			# getBestXAxisTimeFormat = () ->
			# 	if duration is 7
			# 		if interval is 'hour' then return d3.time.format '%H'
			# 		if interval is 'day' then return d3.time.format '%H'

			drawGraph = () ->
				getStartTime = () ->
					timeInDay = 24 * 60 * 60 * 1000
					currentTime = (new Date()).getTime()
					return new Date(currentTime - scope.duration * timeInDay)

				getEndTime = () ->
					return d3.max [new Date(), d3.max(scope.changes, (change) -> return new Date(change.endTime))]
				
				interval = getInterval()
				allIntervals = interval.range interval.floor(getStartTime()), interval.ceil(getEndTime())
				binner = getBinner allIntervals
				histograms = getHistograms binner, interval, allIntervals

				x = d3.time.scale()
					.domain([allIntervals[0], allIntervals[allIntervals.length-1]])
					.range([padding.left+axisBuffer, width-padding.right])
				y = d3.scale.linear()
					.domain([0, 100])
					.range([height-padding.bottom-axisBuffer, padding.top])

				updatePath allLine, histograms.all, x, y, allIntervals, 500
				updatePath passedLine, histograms.passed, x, y, allIntervals, 750
				updatePath failedLine, histograms.failed, x, y, allIntervals, 1000

				xAxis = d3.svg.axis().scale(x).ticks(20).tickFormat(d3.time.format '%m/%d').orient 'bottom'
				yAxis = d3.svg.axis().scale(y).ticks(10).orient 'left'

				xAxisLabel.call xAxis
				yAxisLabel.call yAxis

			clearGraph = () ->
				emptyLine = d3.svg.line()
					.x((d) -> return 0)
					.y((d) -> return 0)

				allLine.attr('d', emptyLine).datum(null) if allLine.datum()?
				passedLine.attr('d', emptyLine).datum(null) if passedLine.datum()?
				failedLine.attr('d', emptyLine).datum(null) if failedLine.datum()?

			handleUpdate = (newValue, oldValue) ->
				if not scope.changes? or scope.changes.length is 0 or not scope.duration? or not scope.interval?
					clearGraph()
				else
					drawGraph()

			scope.$watch 'changes', handleUpdate, true
			scope.$watch 'interval', handleUpdate, true
	])
