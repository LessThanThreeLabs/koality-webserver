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
	factory('ansiParser', ['$window', ($window) ->
		return parse: (text) ->
			return '<span class="ansi">' + $window.ansiParse(text) + '</span>'
	]).
	factory('xUnitParser', ['$window', ($window) ->
		return getTestCases: (xunitOutputs) ->
			testCases = []
			for xunitOutput in xunitOutputs
				testCases = testCases.concat $window.xUnitParse xunitOutput
			return testCases
	]).
	factory('stringHasher', [() ->
		return hash: (text) =>
			return null if typeof text isnt 'string'

			hash = 0
			hash += text.charCodeAt index for index in [0...text.length]
			return hash
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
	])
	