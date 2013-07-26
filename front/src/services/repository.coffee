'use strict'

angular.module('koality.service.repository', []).
	factory('currentChange', ['rpc', 'integerConverter', (rpc, integerConverter) ->
		_id: null
		_information: null

		setChange: (repositoryId, changeId) =>
			console.log repositoryId + ' - ' + changeId
			@_id = changeId
			@_information = null
			return if not repositoryId? or not changeId?

			requestData =
				repositoryId: integerConverter.toInteger repositoryId
				id: integerConverter.toInteger changeId
			rpc 'changes', 'read', 'getMetadata', requestData, (error, changeInformation) =>
				console.log 'change information:'
				console.log changeInformation
				@_information = changeInformation

		getId: () =>
			return @_id

		getInformation: () =>
			return @_information
	]).
	factory('currentStage', ['rpc', 'integerConverter', (rpc, integerConverter) ->
		_id: null
		_information: null

		setStage: (repositoryId, stageId) =>
			@_id = stageId
			@_information = null
			return if not repositoryId? or not stageId?

			requestData =
				repositoryId: integerConverter.toInteger repositoryId
				id: integerConverter.toInteger stageId
			rpc 'buildConsoles', 'read', 'getBuildConsole', requestData, (error, stageInformation) =>
				console.log 'stage information:'
				console.log stageInformation
				@_information = stageInformation

		getId: () =>
			return @_id

		getInformation: () =>
			return @_information
	])