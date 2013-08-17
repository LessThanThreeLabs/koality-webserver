'use strict'

angular.module('koality.service', []).
	factory('localStorage', ['$window', ($window) ->
		return window.localStorage
	]).
	factory('initialState', ['$window', ($window) ->
		toReturn =
			fileSuffix: if $window.fileSuffix is '' then null else $window.fileSuffix
			csrfToken: if $window.csrfToken is '' then null else $window.csrfToken
			user:
				id: if isNaN(parseInt($window.accountInformation?.id)) then null else parseInt($window.accountInformation.id)
				isAdmin: $window.accountInformation?.isAdmin
		toReturn.loggedIn = toReturn.user.id?
		return Object.freeze toReturn
	]).
	factory('fileSuffixAdder', ['initialState', (initialState) ->
		return addFileSuffix: (fileSrc) ->
			lastPeriodIndex = fileSrc.lastIndexOf '.'
			return fileSrc if lastPeriodIndex is -1
			return fileSrc.substr(0, lastPeriodIndex) + initialState.fileSuffix + fileSrc.substr(lastPeriodIndex)
	]).
	factory('integerConverter', [() ->
		return toInteger: (integerAsString) ->
			if typeof integerAsString is 'number'
				if integerAsString isnt Math.floor(integerAsString) then return null
				else return integerAsString

			return null if typeof integerAsString isnt 'string'
			return null if integerAsString.indexOf('.') isnt -1

			integer = parseInt integerAsString
			return null if isNaN integer
			return integer
	]).
	factory('ansiparse', ['$window', ($window) ->
		return parse: (text) ->
			return '<span class="ansi">' + $window.ansiparse(text) + '</span>'
	]).
	factory('xmlParser', ['$window', ($window) ->
		return parse: (xml) ->
			dom = $window.parseXml xml
			json = $window.xml2json dom, ''
			return JSON.parse json
	]).
	factory('cookieExtender', ['$http', ($http) ->
		return extendCookie: (callback) ->
			successHandler = (data, status, headers, config) ->
				callback()
			errorHandler = (data, status, headers, config) ->
				callback 'unable to extend cookie expiration'

			$http.post('/extendCookieExpiration').success(successHandler).error(errorHandler)
	]).
	factory('notification', ['$compile', '$rootScope', '$document', '$timeout', ($compile, $rootScope, $document, $timeout) ->
		container = $document.find '#notificationsContainer'
		
		add = (type, text, durationInSeconds) ->
			assert.ok typeof durationInSeconds is 'number' and durationInSeconds >= 0

			if typeof text is 'object'
				text = (value for key, value of text).join ', '

			notification = "<notification type='#{type}' duration-in-seconds=#{durationInSeconds} unselectable>#{text}</notification>"

			scope = $rootScope.$new(true)
			notification = $compile(notification)(scope)
			$timeout (() -> scope.$apply () -> container.append notification)

		toReturn =
			success: (text, durationInSeconds=8) -> add 'success', text, durationInSeconds
			warning: (text, durationInSeconds=8) -> add 'warning', text, durationInSeconds
			error: (text, durationInSeconds=8) -> add 'error', text, durationInSeconds
		return toReturn
	]).
	factory('changesManager', ['initialState', 'changesRpc', 'events', (initialState, changesRpc, events) ->
		class ChangesManager
			_changes: []
			_gettingMoreChanges: false

			_changeAddedListeners: []
			_changeStartedListeners: []
			_changeFinishedListeners: []

			constructor: (@repositoryIds, @searchModel) ->
				assert.ok typeof @repositoryIds is 'object'
				assert.ok typeof @searchModel is 'object'

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

					stingsToMatch = @searchModel.query.trim().split(' ')
						.filter((string) -> return string isnt '')
						.map((string) -> return string.toLowerCase())

					return (change.user.name.first.toLowerCase() in stringsToMatch) or
						(change.user.name.last.toLowerCase() in stringsToMatch) or
						(change.headCommit.sha.toLowerCase() in stringsToMatch)

			_getChangeWithId: (id) =>
				return (change for change in @_changes when change.id is id)[0]

			_initialChangesHandler: (error, changes) =>
				@_gettingMoreChanges = false
				@_changes = changes

			_moreChangesHandler: (error, additionalChanges) =>
				@_gettingMoreChanges = false
				@_changes = @_changes.concat additionalChanges

			_handleChangeAdded: (data) =>
				if _doesChangeMatchQuery(data) and not _getChangeWithId(data.id)?
					@_changes.unshift data

			_handleChangeStarted: (data) =>
				# @changeStartedHandler data if @changeStartedHandler?

			_handleChangeFinished: (data) =>
				# @changeFinishedHandler data if @changeFinishedHandler?

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
				@_gettingMoreChanges = true
				changesRpc.queueRequest @repositoryIds, @_getGroupFromMode(), @_getQuery(), 0, @_initialChangesHandler

			getMoreChanges: () =>
				@_gettingMoreChanges = true
				changesRpc.queueRequest @repositoryIds, @_getGroupFromMode(), @_getQuery(), @_changes.length, @_moreChangesHandler	

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


		return create: (repositoryIds, search) ->
			return new ChangesManager repositoryIds, search
	])
	