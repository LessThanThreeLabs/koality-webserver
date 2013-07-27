'use strict'

angular.module('koality.service.repository', []).
	factory('currentRepository', ['rpc', 'integerConverter', (rpc, integerConverter) ->
		_id: null
		_information: null

		setRepository: (repositoryId) =>
			return if @_id is repositoryId
			console.log 'repository: ' + repositoryId

			@_id = integerConverter.toInteger repositoryId
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
			return if @_id is changeId
			console.log 'change:' + repositoryId + ' - ' + changeId

			@_id = integerConverter.toInteger changeId
			@_information = null

			return if not repositoryId? or not changeId?

			requestData =
				repositoryId: integerConverter.toInteger repositoryId
				id: integerConverter.toInteger changeId
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
			return if @_id is stageId
			console.log 'stage: ' + repositoryId + ' - ' + stageId

			@_id = integerConverter.toInteger stageId
			@_information = null
			@_summary = false
			@_skipped = false
			@_merge = false
			@_debug = false

			return if not repositoryId? or not stageId?

			requestData =
				repositoryId: integerConverter.toInteger repositoryId
				id: integerConverter.toInteger stageId
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