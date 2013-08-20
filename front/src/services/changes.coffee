'use strict'

angular.module('koality.service.changes', []).
	factory('ChangesManager', ['ChangesRpc', 'events', (ChangesRpc, events) ->
		class ChangesManager
			_changes: []
			_changesCache: {}
			_gettingMoreChanges: false
			_currentRequestId: null

			_changeAddedListeners: []
			_changeStartedListeners: []
			_changeFinishedListeners: []

			constructor: (@repositoryIds, @searchModel) ->
				assert.ok typeof @repositoryIds is 'object'
				assert.ok typeof @searchModel is 'object'

				@changesRpc = ChangesRpc.create()

			_getGroupFromMode: () =>
				if @searchModel.mode is 'all' or @searchModel.mode is 'me'
					return @searchModel.mode
				if @searchModel.query.trim() is ''
					return 'all'
				return null

			_getQuery: () =>
				if @searchModel.mode isnt 'search' then return null

				query = @searchModel.query.trim()
				if query is '' then return null
				else return query

			_doesChangeMatchQuery: (change) =>
				if @searchModel.mode is 'me'
					return initialState.user.id is change.user.id
				else
					return true if @searchModel.query.trim() is ''

					stringsToMatch = @searchModel.query.trim().split(' ')
						.filter((string) -> return string isnt '')
						.map((string) -> return string.toLowerCase())

					return (change.user.name.first.toLowerCase() in stringsToMatch) or
						(change.user.name.last.toLowerCase() in stringsToMatch) or
						(change.headCommit.sha.toLowerCase() in stringsToMatch)

			_changesRetrievedHandler: (error, changesData) =>
				return if @_currentRequestId isnt changesData.requestId

				changesData.changes = changesData.changes.filter (change) =>
					return not @_changesCache[change.id]?

				@_changesCache[change.id] = change for change in changesData.changes
				@_changes = @_changes.concat changesData.changes
				@_gettingMoreChanges = false

			_handleChangeAdded: (data) =>
				if @_doesChangeMatchQuery(data) and not @_changesCache[data.id]?
					@_changesCache[data.id] = data
					@_changes.unshift data

			_handleChangeStarted: (data) =>
				change = @_changesCache[data.id]
				$.extend true, change, data if change?

			_handleChangeFinished: (data) =>
				change = @_changesCache[data.id]
				$.extend true, change, data if change?

			_addListeners: (listeners, eventType, handler) =>
				@_removeListeners listeners

				for repositoryId in @repositoryIds
					listener = events('repositories', eventType, repositoryId).setCallback(handler).subscribe()
					listeners.push listener

			_removeListeners: (listeners) =>
				listener.unsubscribe() for listener in listeners
				listeners.length = 0

			getInitialChanges: () =>
				@_changes = []
				@_changesCache = {}
				@_gettingMoreChanges = true
				@_currentRequestId = @changesRpc.queueRequest @repositoryIds, @_getGroupFromMode(), @_getQuery(), 0, @_changesRetrievedHandler

			getMoreChanges: () =>
				return if @_changes.length is 0
				return if @_gettingMoreChanges
				return if not @changesRpc.hasMoreChangesToRequest()
				@_gettingMoreChanges = true
				@_currentRequestId = @changesRpc.queueRequest @repositoryIds, @_getGroupFromMode(), @_getQuery(), @_changes.length, @_changesRetrievedHandler	

			getChanges: () =>
				return @_changes

			isGettingMoreChanges: () =>
				return @_gettingMoreChanges

			listenToEvents: () =>
				@_addListeners @_changeAddedListeners, 'change added', @_handleChangeAdded
				@_addListeners @_changeStartedListeners, 'change started', @_handleChangeStarted
				@_addListeners @_changeFinishedListeners, 'change finished', @_handleChangeFinished
					
			stopListeningToEvents: () =>
				@_removeListeners @_changeAddedListeners
				@_removeListeners @_changeStartedListeners
				@_removeListeners @_changeFinishedListeners


		return create: (repositoryIds, searchModel) ->
			return new ChangesManager repositoryIds, searchModel
	]).
	factory('StagesManager', ['rpc', 'events', (rpc, events) ->
		class StagesManager
			_changeId: null

			_stages: []
			_stagesCache: {}
			_gettingStages: false

			_stageAddedListener: null
			_stageUpdatedListener: null

			_stagesRetrievedHandler: (error, stagesToAdd) =>
				stagesToAdd = stagesToAdd.filter (stage) => return not @_stagesCache[stage.id]?

				@_stagesCache[stage.id] = stage for stage in stagesToAdd
				@_stages = @_stages.concat stagesToAdd
				@_gettingStages = false

			_handleStageAdded: (data) =>
				if not @_stagesCache[data.id]?
					@_stagesCache[data.id] = data
					@_stages.push data

			_handleStageUpdated: (data) =>
				stage = @_stagesCache[data.id]
				$.extend true, stage, data if stage?

			setChangeId: (changeId) =>
				assert.ok typeof changeId is 'number'

				if @_changeId isnt changeId
					@_stages = []
					@_stagesCache = {}					
					@_changeId = changeId

			retrieveStages: () =>
				assert.ok @_changeId?

				@_stages = []
				@_stagesCache = {}
				@_gettingStages = true

				rpc 'buildConsoles', 'read', 'getBuildConsoles', changeId: @_changeId, @_stagesRetrievedHandler

			getStages: () =>
				return @_stages

			isGettingStages: () =>
				return @_gettingStages

			listenToEvents: () =>
				assert.ok @_changeId?

				@stopListeningToEvents()

				buildConsoleAddedEvents = events('changes', 'new build console', @_changeId).setCallback(@_handleStageAdded).subscribe()
				buildConsoleStatusUpdateEvents = events('changes', 'return code added', @_changeId).setCallback(@_handleStageUpdated).subscribe()
					
			stopListeningToEvents: () =>
				@_stageAddedListener.unsubscribe() if @_stageAddedListener?
				@_stageUpdatedListener.unsubscribe() if @_stageUpdatedListener?

				@_stageAddedListener = null
				@_stageUpdatedListener = null

		return create: () ->
			return new StagesManager()
	])