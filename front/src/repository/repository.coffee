'use strict'

window.Repository = ['$scope', '$location', '$routeParams', 'rpc', 'events', 'currentChange', 'currentStage', ($scope, $location, $routeParams, rpc, events, currentChange, currentStage) ->
	$scope.selectedChange = currentChange
	$scope.selectedStage = currentStage

	retrieveRepositoryInformation = () ->
		rpc 'repositories', 'read', 'getMetadata', id: $routeParams.repositoryId, (error, repositoryInformation) ->
			$scope.repository = repositoryInformation

	syncToRouteParams = () ->
		$scope.selectedChange.setChange $routeParams.repositoryId, $routeParams.change
		$scope.selectedStage.setStage $routeParams.repositoryId, $routeParams.stage if $routeParams.stage?
		$scope.selectedStage.setSummary() if not $routeParams.stage?
		$scope.selectedStage.setSkipped() if $routeParams.skipped?
		$scope.selectedStage.setMerge() if $routeParams.merge?
		$scope.selectedStage.setDebug() if $routeParams.debug?
	$scope.$on '$routeUpdate', syncToRouteParams
	syncToRouteParams()

	retrieveRepositoryInformation()

	$scope.$watch 'selectedChange.getId()', (newValue) ->
		$location.search 'change', newValue ? null

	$scope.$watch 'selectedStage.getId()', (newValue) ->
		$location.search 'stage', newValue ? null

	$scope.$watch 'selectedStage.isSkipped()', (newValue) ->
		$location.search 'skipped', if newValue then true else null

	$scope.$watch 'selectedStage.isMerge()', (newValue) ->
		$location.search 'merge', if newValue then true else null

	$scope.$watch 'selectedStage.isDebug()', (newValue) ->
		$location.search 'debug', if newValue then true else null
]
