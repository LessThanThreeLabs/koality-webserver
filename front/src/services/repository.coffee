'use strict'

angular.module('koality.service.repository', []).
	factory('currentRepository', ['rpc', 'integerConverter', (rpc, integerConverter) ->
		_id: null
		_information: null

		clear: () =>
			@_id = null
			@_information = null

		setId: (repositoryId) =>
			@_id = integerConverter.toInteger repositoryId
			@_information = null

		getId: () =>
			return @_id

		setInformation: (repositoryInformation) =>
			assert.ok @_id?
			assert.ok repositoryInformation?
			@_information = repositoryInformation

		retrieveInformation: () =>
			assert.ok @_id
			rpc 'repositories', 'read', 'getMetadata', id: @_id, (error, repositoryInformation) =>
				@_information = repositoryInformation

		getInformation: () =>
			return @_information
	]).
	factory('currentChange', ['rpc', 'integerConverter', (rpc, integerConverter) ->
		_repositoryId: null
		_id: null
		_information: null

		clear: () =>
			@_repositoryId = null
			@_id = null
			@_information = null

		setId: (repositoryId, changeId) =>
			@_repositoryId = integerConverter.toInteger repositoryId
			@_id = integerConverter.toInteger changeId
			@_information = null

		getId: () =>
			return @_id

		setInformation: (changeInformation) =>
			assert.ok @_repositoryId?
			assert.ok @_id?
			assert.ok changeInformation?
			@_information = changeInformation

		retrieveInformation: () =>
			assert.ok @_repositoryId?
			assert.ok @_id?

			requestData =
				repositoryId: @_repositoryId
				id: @_id
			rpc 'changes', 'read', 'getChange', requestData, (error, changeInformation) =>
				@_information = changeInformation

		getInformation: () =>
			return @_information
	]).
	factory('currentStage', ['rpc', 'integerConverter', (rpc, integerConverter) ->
		_repositoryId: null
		_changeId: null
		_id: null
		_information: null
		_summary: false
		_skipped: false
		_merge: false
		_debug: false

		clear: () =>
			@_repositoryId = null
			@_id = null
			@_information = null

		setId: (repositoryId, changeId, stageId) =>
			@_repositoryId = integerConverter.toInteger repositoryId
			@_changeId = integerConverter.toInteger changeId
			@_id = integerConverter.toInteger stageId
			@_information = null
			@_summary = false
			@_skipped = false
			@_merge = false
			@_debug = false

		getId: () =>
			return @_id

		setInformation: (stageInformation) =>
			assert.ok @_repositoryId?
			assert.ok @_changeId?
			assert.ok @_id?
			assert.ok stageInformation?
			@_information = stageInformation

		retrieveInformation: () =>
			assert.ok @_repositoryId?
			assert.ok @_changeId?
			assert.ok @_id?

			requestData =
				repositoryId: @_repositoryId
				id: @_id
			rpc 'buildConsoles', 'read', 'getBuildConsole', requestData, (error, stageInformation) =>
				@_information = stageInformation

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