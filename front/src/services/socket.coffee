'use strict'

angular.module('koality.service.socket', []).
	factory('socket', ['$window', '$location', '$timeout', 'initialState', 'notification', ($window, $location, $timeout, initialState, notification) ->
		maxReconnectionAttempts = 10

		socket = io.connect "//#{$location.host()}?csrfToken=#{initialState.csrfToken}",
			'resource': 'socket'
			'connection timeout': 5000
			'reconnection delay': 200
			'reconnection limit': 1000
			'max reconnection attempts': maxReconnectionAttempts

		socket.on 'reconnecting', (delay, attempt) ->
			if attempt >= maxReconnectionAttempts
				notification.warning 'Unable to connect to server. Refreshing may resolve this issue', 0

		previousEventToCallbacks = {}

		makeRequest: (resource, requestType, methodName, data, timeout, callback) ->
			assert.ok typeof resource is 'string' and typeof requestType is 'string' and typeof methodName is 'string'
			assert.ok resource.indexOf('.') is -1 and requestType.indexOf('.') is -1
			assert.ok typeof requestType is 'string'
			assert.ok typeof methodName is 'string'
			assert.ok typeof data is 'object'
			assert.ok typeof timeout is 'number'
			assert.ok typeof callback is 'function'

			requestHandled = false
			handleResponse = (error, response) ->
				$timeout.cancel timeoutPromise if timeoutPromise?

				return if requestHandled
				requestHandled = true

				if error?
					console.error "#{resource}.#{requestType} - #{methodName}"
					console.error error
				switch error
					when 400, 404, 500 then window.location.href = '/unexpectedError'
					when 403 then window.location.href = '/invalidPermissions'
					else callback error, response if callback?

			if timeout > 0
				timeoutPromise = $timeout (() -> handleResponse 'Timed out'), timeout

			socket.emit "#{resource}.#{requestType}", {method: methodName, args: data}, handleResponse

		respondTo: (eventName, callback) ->
			if not previousEventToCallbacks[eventName]?
				socket.on eventName, callback
				previousEventToCallbacks[eventName] = [callback]
			else
				for otherCallback in previousEventToCallbacks[eventName]
					return if callback is otherCallback

				socket.on eventName, callback
				previousEventToCallbacks[eventName].push callback
	]).
	factory('rpc', ['$rootScope', 'socket', ($rootScope, socket) ->
		defaultTimeout = 30000

		return (resource, requestType, methodName, data, allowTimeout, callback) ->
			# specifying the timeout isn't necessary
			if not callback?
				callback = allowTimeout
				timeout = defaultTimeout
			else
				timeout = if allowTimeout then defaultTimeout else -1

			socket.makeRequest resource, requestType, methodName, data, timeout, (error, result) ->
				if callback? then $rootScope.$apply () -> callback error, result
	]).
	factory('events', ['$rootScope', 'socket', 'integerConverter', ($rootScope, socket, integerConverter) ->
		class EventListener
			constructor: (@resource, @eventName, id) ->
				@_callback = null
				@id = integerConverter.toInteger id

			setCallback: (callback) =>
				assert.ok callback?
				@_callback = callback
				return @

			subscribe: () =>
				assert.ok @_callback?
				socket.makeRequest @resource, 'subscribe', @eventName, id: @id, 30000, (error, eventToListenFor) =>
					if error? then console.error error
					else socket.respondTo eventToListenFor, (data) =>
						if @_callback? then $rootScope.$apply () => @_callback data 
				return @

			unsubscribe: () =>
				@_callback = null
				socket.makeRequest @resource, 'unsubscribe', @eventName, id: @id, 30000, (error) ->
					console.error if error?
				return @

		return (resource, eventName, id) ->
			return new EventListener resource, eventName, id
	]).
	factory('changesRpc', ['rpc', 'integerConverter', (rpc, integerConverter) ->
		NUM_CHANGES_TO_REQUEST = 100
		noMoreChangesToRequest = false

		currentQuery = null
		currentCallback = null
		nextQuery = null
		nextCallback = null

		createChangesQuery = (repositoryIds, group, query, startIndex) ->
			repositoryIds: repositoryIds
			group: group
			query: query
			startIndex: startIndex
			numToRetrieve: NUM_CHANGES_TO_REQUEST

		shiftChangesRequest = () ->
			if not nextQuery?
				currentQuery = null
				currentCallback = null
			else
				currentQuery = nextQuery
				currentCallback = nextCallback
				nextQuery = null
				nextCallback = null

				retrieveMoreChanges()

		retrieveMoreChanges = () ->
			assert.ok currentQuery?
			assert.ok currentCallback?

			noMoreChangesToRequest = false if currentQuery.startIndex is 0

			if noMoreChangesToRequest
				shiftChangesRequest()
			else
				rpc 'changes', 'read', 'getChanges', currentQuery, (error, changes) ->
					noMoreChangesToRequest = changes.length < NUM_CHANGES_TO_REQUEST
					currentCallback error, changes
					shiftChangesRequest()

		return queueRequest: (repositoryIds, group, query, startIndex, callback) ->
			assert.ok typeof repositoryIds is 'object' and repositoryIds.length > 0
			assert.ok not group? or (typeof group is 'string' and (group is 'all' or group is 'me'))
			assert.ok not query? or (typeof query is 'string')
			assert.ok (group? and not query?) or (not group? and query?)
			assert.ok typeof startIndex is 'number'
			assert.ok typeof callback is 'function'

			repositoryIds = repositoryIds.map (repositoryId) -> return integerConverter.toInteger repositoryId

			if currentQuery?
				nextQuery = createChangesQuery repositoryIds, group, query, startIndex
				nextCallback = callback
			else
				currentQuery = createChangesQuery repositoryIds, group, query, startIndex
				currentCallback = callback
				retrieveMoreChanges()
	])