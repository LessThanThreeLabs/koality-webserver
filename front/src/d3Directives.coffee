'use strict'

angular.module('koality.d3.directive', []).
	directive('changeAnalytics', ['$window', ($window) ->
		restrict: 'E'
		replace: true
		scope: 
			changes: '='
			startTime: '='
			endTime: '='
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

			drawGraph = () ->
				console.log 'drawing graph...'

				d3Binner = D3Binner.create scope.changes, scope.startTime, scope.endTime, scope.interval

				allIntervals = d3Binner.getAllIntervals()
				histograms = d3Binner.getHistograms()

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
				console.log 'in handle update'
				if not scope.changes? or scope.changes.length is 0 or not scope.startTime? or not scope.endTime? or not scope.interval?
					clearGraph()
				else
					drawGraph()

			scope.$watch 'changes', handleUpdate, true
			scope.$watch 'interval', handleUpdate, true
	])
