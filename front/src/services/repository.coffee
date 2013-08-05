'use strict'

angular.module('koality.service.repository', []).
	factory('currentRepository', ['rpc', 'integerConverter', (rpc, integerConverter) ->
		_id: null
		_information: null

		setRepository: (repositoryId) =>
			repositoryId = integerConverter.toInteger repositoryId
			return if @_id is repositoryId

			@_id = repositoryId
			@_information = null

			return if not repositoryId?

			requestData =
				id: integerConverter.toInteger repositoryId
			rpc 'repositories', 'read', 'getMetadata', requestData, (error, repositoryInformation) =>
				@_information = repositoryInformation

		getId: () =>
			return @_id

		getInformation: () =>
			return @_information
	]).
	factory('currentChange', ['rpc', 'integerConverter', (rpc, integerConverter) ->
		_id: null
		_information: null

		setChange: (repositoryId, changeId) =>
			repositoryId = integerConverter.toInteger repositoryId
			changeId = integerConverter.toInteger changeId
			return if @_id is changeId

			@_id = changeId
			@_information = null

			return if not repositoryId? or not changeId?

			requestData =
				repositoryId: repositoryId
				id: changeId
			rpc 'changes', 'read', 'getMetadata', requestData, (error, changeInformation) =>
				@_information = changeInformation

		getId: () =>
			return @_id

		getInformation: () =>
			return @_information
	]).
	factory('currentStage', ['rpc', 'integerConverter', (rpc, integerConverter) ->
		_id: null
		_information: null
		_summary: false
		_skipped: false
		_merge: false
		_debug: false

		setStage: (repositoryId, stageId) =>
			repositoryId = integerConverter.toInteger repositoryId
			stageId = integerConverter.toInteger stageId
			return if @_id is stageId

			@_id = stageId
			@_information = null
			@_summary = false
			@_skipped = false
			@_merge = false
			@_debug = false

			return if not repositoryId? or not stageId?

			requestData =
				repositoryId: repositoryId
				id: stageId
			rpc 'buildConsoles', 'read', 'getBuildConsole', requestData, (error, stageInformation) =>
				@_information = stageInformation

		getId: () =>
			return @_id

		getInformation: () =>
			return @_information

		setSummary: () =>
			@_id = null
			@_information = null
			@_summary = true
			@_skipped = false
			@_merge = false
			@_debug = false

		isSummary: () =>
			return @_summary

		setSkipped: () =>
			@_id = null
			@_information = null
			@_summary = false
			@_skipped = true
			@_merge = false
			@_debug = false

		isSkipped: () =>
			return @_skipped

		setMerge: () =>
			@_id = null
			@_information = null
			@_summary = false
			@_skipped = false
			@_merge = true
			@_debug = false

		isMerge: () =>
			return @_merge

		setDebug: () =>
			@_id = null
			@_information = null
			@_summary = false
			@_skipped = false
			@_merge = false
			@_debug = true

		isDebug: () =>
			return @_debug
	])