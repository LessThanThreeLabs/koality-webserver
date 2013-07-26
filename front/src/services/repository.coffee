'use strict'

angular.module('koality.service.repository', []).
	factory('currentChange', ['rpc', 'integerConverter', (rpc, integerConverter) ->
		_id: null
		_information: null

		setChange: (repositoryId, changeId) =>
			return if @_id is changeId

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
		_summary: false
		_skipped: false
		_merge: false
		_debug: false

		setStage: (repositoryId, stageId) =>
			return if @_id is stageId

			@_id = stageId
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
				console.log 'stage information:'
				console.log stageInformation
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