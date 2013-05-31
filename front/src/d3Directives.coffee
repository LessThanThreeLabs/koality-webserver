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
			d3ChangesLineGraph = D3ChangesLineGraph.create element

			handleUpdate = (newValue, oldValue) ->
				if not scope.changes? or scope.changes.length is 0 or not scope.startTime? or not scope.endTime? or not scope.interval?
					# clearGraph()
					console.log 'need to clear graph...'
				else
					d3Binner = D3Binner.create scope.changes, scope.startTime, scope.endTime, scope.interval
					d3ChangesLineGraph.drawGraph d3Binner

			scope.$watch 'changes', handleUpdate, true
			scope.$watch 'interval', handleUpdate, true
	])
