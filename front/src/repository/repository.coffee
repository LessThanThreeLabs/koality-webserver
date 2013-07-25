'use strict'

copyDataIntoChange = (change, data) ->
	assert.ok change? and typeof change is 'object'
	assert.ok data? and typeof data is 'object'

	if data.aggregateStatus? then change.aggregateStatus = data.aggregateStatus
	if data.verificationStatus? then change.verificationStatus = data.verificationStatus
	if data.mergeStatus? then change.mergeStatus = data.mergeStatus
	if data.createTime? then change.createTime = data.createTime
	if data.startTime? then change.startTime = data.startTime
	if data.endTime? then change.endTime = data.endTime


window.Repository = ['$scope', '$location', '$routeParams', 'rpc', 'events', 'integerConverter', ($scope, $location, $routeParams, rpc, events, integerConverter) ->
	retrieveRepositoryInformation = () ->
		rpc 'repositories', 'read', 'getMetadata', id: $routeParams.repositoryId, (error, repositoryInformation) ->
			$scope.repository = repositoryInformation

	retrieveCurrentChangeInformation = () ->
		$scope.currentChangeInformation = null
		return if not $scope.currentChangeId?

		requestData =
			repositoryId: integerConverter.toInteger $routeParams.repositoryId
			id: $scope.currentChangeId

		rpc 'changes', 'read', 'getMetadata', requestData, (error, changeInformation) ->
			$scope.currentChangeInformation = changeInformation
			$scope.showSkipped = false if $scope.currentChangeInformation.aggregateStatus isnt 'skipped'
			$scope.showMerge = false if not $scope.currentChangeInformation.mergeStatus?
			$scope.showDebug = false if $scope.currentChangeInformation.aggregateStatus isnt 'failed'

	retrieveCurrentStageInformation = () ->
		$scope.currentStageInformation = null
		return if not $scope.currentStageId?

		requestData =
			repositoryId: integerConverter.toInteger $routeParams.repositoryId
			id: $scope.currentStageId

		rpc 'buildConsoles', 'read', 'getBuildConsole', requestData, (error, stageInformation) ->
			$scope.currentStageInformation = stageInformation

	syncToRouteParams = () ->
		$scope.currentChangeId = integerConverter.toInteger $routeParams.change
		$scope.currentStageId = integerConverter.toInteger $routeParams.stage
		$scope.showSkipped = $routeParams.skipped?
		$scope.showMerge = $routeParams.merge?
		$scope.showDebug = $routeParams.debug?
	$scope.$on '$routeUpdate', syncToRouteParams
	syncToRouteParams()

	$scope.selectChange = (change) ->
		$scope.currentChangeId = change?.id
		$scope.currentStageId = null
		$scope.showSkipped = false
		$scope.showMerge = false
		$scope.showDebug = false

	$scope.selectStage = (stage) ->
		$scope.currentStageId = stage?.id
		$scope.showSkipped = false
		$scope.showMerge = false
		$scope.showDebug = false

	$scope.selectSkipped = () ->
		$scope.currentStageId = null
		$scope.showSkipped = true
		$scope.showMerge = false
		$scope.showDebug = false

	$scope.selectMerge = () ->
		$scope.currentStageId = null
		$scope.showSkipped = false
		$scope.showMerge = true
		$scope.showDebug = false

	$scope.selectDebug = () ->
		$scope.currentStageId = null
		$scope.showSkipped = false
		$scope.showMerge = false
		$scope.showDebug = true

	$scope.$watch 'currentChangeId', (newValue, oldValue) ->
		retrieveCurrentChangeInformation()
		$location.search 'change', newValue ? null

	$scope.$watch 'currentStageId', (newValue, oldValue) ->
		retrieveCurrentStageInformation()
		$location.search 'stage', newValue ? null

	$scope.$watch 'showSkipped', (newValue, oldValue) ->
		$location.search 'skipped', if newValue then true else null

	$scope.$watch 'showMerge', (newValue, oldValue) ->
		$location.search 'merge', if newValue then true else null

	$scope.$watch 'showDebug', (newValue, oldValue) ->
		$location.search 'debug', if newValue then true else null

	retrieveRepositoryInformation()
]
