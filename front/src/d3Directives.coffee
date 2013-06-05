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
			graphType: '='
		template: '<div class="d3ChangesLineGraph">
				<svg xmlns="http://www.w3.org/2000/svg" version="1.1"></svg>
			</div>'
		link: (scope, element, attributes) ->
			d3ChangesLineGraph = D3ChangesLineGraph.create element
			changesListWasEmpty = true

			handleUpdate = (newValue, oldValue) ->
				if scope.startTime? and scope.endTime? and scope.interval?
					changes = scope.changes ? []
					d3Binner = D3Binner.create changes, scope.startTime, scope.endTime, scope.interval

					if scope.graphType is 'all' then d3ChangesLineGraph.drawGraph d3Binner, changesListWasEmpty
					else d3ChangesLineGraph.drawPercentageGraph d3Binner, scope.graphType, changesListWasEmpty

					changesListWasEmpty = changes.length is 0

			scope.$watch 'changes', handleUpdate, true
			scope.$watch 'graphType',  handleUpdate
			scope.$watch 'startTime', handleUpdate
			scope.$watch 'endTime', handleUpdate
			scope.$watch 'interval', handleUpdate
	])
