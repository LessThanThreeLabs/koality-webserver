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

		setInformation: (repositoryInformation) =>
			assert.ok @_id?
			assert.ok repositoryInformation?
			@_information = repositoryInformation

		retrieveInformation: () =>
			assert.ok @_id
			rpc 'repositories', 'read', 'getMetadata', id: @_id, (error, repositoryInformation) =>
				@_information = repositoryInformation

		getId: () =>
			return @_id

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
			rpc 'changes', 'read', 'getMetadata', requestData, (error, changeInformation) =>
				@_information = changeInformation

		getId: () =>
			return @_id

		getInformation: () =>
			return @_information
	]).
	factory('currentStage', ['rpc', 'integerConverter', (rpc, integerConverter) ->
		_repositoryId: null
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

		setId: (repositoryId, stageId) =>
			@_id = integerConverter.toInteger stageId

		setInformation: (stageInformation) =>
			assert.ok @_repositoryId?
			assert.ok @_id?
			assert.ok stageInformation?
			@_information = stageInformation

		# setStage: (repositoryId, stageId) =>
		# 	repositoryId = integerConverter.toInteger repositoryId
		# 	stageId = integerConverter.toInteger stageId
		# 	return if @_id is stageId

		# 	@_id = stageId
		# 	@_information = null
		# 	@_summary = false
		# 	@_skipped = false
		# 	@_merge = false
		# 	@_debug = false

		# 	return if not repositoryId? or not stageId?

		# 	requestData =
		# 		repositoryId: repositoryId
		# 		id: stageId
		# 	rpc 'buildConsoles', 'read', 'getBuildConsole', requestData, (error, stageInformation) =>
		# 		@_information = stageInformation
		# 		@_information.hasJUnit = true

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