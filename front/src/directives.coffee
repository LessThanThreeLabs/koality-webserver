'use strict'

angular.module('koality.directive', []).
	directive('focused', () ->
		return (scope, element, attributes) ->
			element.focus()
	).
	directive('inputFocusOnClick', () ->
		return (scope, element, attributes) ->
			element.bind 'click', (event) ->
				element.find('input').focus()
	).
	directive('highlightOnClick', () ->
		return (scope, element, attributes) ->
			highlightText = () ->
				element.select()
				element.unbind 'click', highlightText if attributes.firstOnly?

			element.bind 'click', highlightText
	).
	directive('autoFillableField', () ->
		# This is a hack until the following bug is fixed:
		# https://github.com/angular/angular.js/issues/1460
		return (scope, element, attributes) ->
			element.on 'change.autofill DOMAttrModified.autofill keydown.autofill propertychange.autofill', () ->
				element.trigger 'input' if element.val() isnt ''
	).
	directive('hideOnExternalClick', ['$document', '$timeout', ($document, $timeout) ->
		restrict: 'A'
		link: (scope, element, attributes) ->
			addListeners = () ->
				element.bind 'click', handleInternalClick
				$timeout (() -> $document.bind 'click', handleExternalClick)

			removeListeners = () ->
				element.unbind 'click', handleInternalClick
				$document.unbind 'click', handleExternalClick

			handleInternalClick = (event) ->
				event.stopPropagation()

			handleExternalClick = () ->
				scope.$apply attributes.hideFunction

			scope.$watch attributes.hideOnExternalClick, () ->
				if scope.$eval attributes.hideOnExternalClick then addListeners()
				else removeListeners()
	]).
	directive('licenseKey', () ->
		restrict: 'A'
		require: 'ngModel'
		link: (scope, element, attributes, control) ->
			control.$parsers.unshift (viewValue) ->
				return viewValue if not viewValue?

				cleanedValue = viewValue.replace /[^a-zA-Z0-9]/g, ''
				control.$setValidity 'licenseKey', cleanedValue.length is 16

				return if cleanedValue.length is 16 then cleanedValue else undefined
	).
	directive('fadingContent', () ->
		restrict: 'A'
		replace: true
		transclude: true
		template: '<div class="fadingContentContainer">
				<div class="fadingContentTopBuffer"></div>
				<div class="fadingContentScrollWrapper autoScrollToBottomDirectiveAnchor onScrollToBottomDirectiveAnchor">
					<div class="fadingContent" ng-transclude></div>
				</div>
				<div class="fadingContentBottomBuffer"></div>
			</div>'
		link: (scope, element, attributes) ->
			fadingContentElement = element.find('.fadingContent')
			fadingContentElement.width element.width()
	).
	directive('autoScrollToBottom', ['$timeout', 'integerConverter', ($timeout, integerConverter) ->
		restrict: 'A'
		link: (scope, element, attributes) ->
			if element.find('.autoScrollToBottomDirectiveAnchor').length > 0
				element = element.find '.autoScrollToBottomDirectiveAnchor'

			scrollToBottom = () ->
				$timeout (() -> element[0].scrollTop = element[0].scrollHeight)

			scrollBottomBuffer = integerConverter.toInteger(attributes.autoScrollToBottomBuffer) ? 20

			scope.$watch attributes.autoScrollToBottom, ((newValue, oldValue) ->
				if oldValue? and oldValue.length > 0
					isScrolledToBottomIsh = element[0].scrollTop + element[0].offsetHeight + scrollBottomBuffer >= element[0].scrollHeight
					scrollToBottom() if isScrolledToBottomIsh
				else
					scrollToBottom() if attributes.startAtBottom?
			), true
	]).
	directive('onScrollToBottom', [() ->
		restrict: 'A'
		link: (scope, element, attributes) ->
			if element.find('.onScrollToBottomDirectiveAnchor').length > 0
				element = element.find '.onScrollToBottomDirectiveAnchor'

			addScrollListener = () ->
				element.bind 'scroll', (event) ->
					scrolledToBottom = element[0].scrollTop + element[0].offsetHeight >= element[0].scrollHeight
					scope.$apply attributes.onScrollToBottom if scrolledToBottom

			addScrollListener()
	]).
	directive('busyButton', ['$timeout', ($timeout) ->
		restrict: 'E'
		replace: true
		transclude: true
		scope:
			show: '=show'
			busy: '=busy'
			disabled: '=disabled'
			clickHandler: '&click'
		template: '<div class="busyButton" ng-show="(show != null && show) || (show == null)">
				<button ng-show="!busy" ng-mouseup="click($event)" ng-click="click($event)" ng-disabled="disabled" ng-transclude></button>
				<spinner white spinner-running="busy" class="busyButtonSpinner"></spinner>
			</div>'
		link: (scope, element, attributes) ->
			element.css
				position: 'relative'
				'z-index': 1

			button = element.find 'button'
			button.addClass 'centered' if attributes.centered?
			button.addClass 'fullWidth' if attributes.fullWidth?
			button.addClass 'red' if attributes.red?

			spinner = element.find '.busyButtonSpinner'
			spinner.css
				position: 'absolute'
				top: 0
				left: 0
				right: 0
				bottom: 0
				'z-index': -1

			element.width Math.max button.outerWidth(), 25 if not attributes.centered?
			element.height Math.max button.outerHeight(), 25

			# This allows us to have more responsive buttons that respond to
			# mouseup (because buttons are buggy in osx...) while still supporting
			# form submission logic (clicking the enter key while focus is in a form)
			ignoreClickEvents = false
			scope.click = (event) ->
				return if ignoreClickEvents
				ignoreClickEvents = true

				scope.clickHandler()

				$timeout (() -> ignoreClickEvents = false), 100
	]).
	directive('spinner', () ->
		restrict: 'E'
		replace: true
		scope: running: '=spinnerRunning'
		template: '<div class="spinnerContainer"></div>'
		link: (scope, element, attributes) ->
			spinner = null

			spinnerOptions =
				lines: 7
				length: 3
				width: 3
				radius: 5
				corners: 1
				rotate: 14
				color: '#FFFFFF'
				speed: 1.2
				trail: 30
				shadow: false
				hwaccel: true
				className: 'spinner'
				zIndex: 2e9
				top: 'auto'
				left: 'auto'

			scope.$watch 'running', (newValue, oldValue) ->
				if newValue then startSpinner() else stopSpinner()

			startSpinner = () ->
				spinner = new Spinner(spinnerOptions).spin(element[0])

			stopSpinner = () ->
				spinner.stop() if spinner?
	).
	directive('notification', ['$timeout', ($timeout) ->
		restrict: 'E'
		replace: true
		transclude: true
		scope:
			type: '@'
			durationInSeconds: '@'
		template: '<div class="notification" ng-class="{green: type == \'success\', orange: type == \'warning\', red: type == \'error\'}">
					<div class="notificationContent growingCentered">
						<span class="notificationMessage" ng-transclude></span>
						<span class="notificationClose" ng-click="hide()">X</span>
					</div>
				</div>'
		link: (scope, element, attributes) ->
			getZIndex = (type, transient) ->
				minorIndex = 0
				switch type
					when 'success' then minorIndex = 100
					when 'warning' then minorIndex = 200
					when 'error' then minorIndex = 300
					else throw 'unexpected notification type ' + type
				return if transient then minorIndex + 1000 else minorIndex

			scope.hide = () ->
				element.addClass 'hiding'
				$timeout (() -> element.remove()), 5000

			element.css 'z-index', getZIndex attributes.type, attributes.durationInSeconds > 0
			$timeout scope.hide, attributes.durationInSeconds * 1000 if attributes.durationInSeconds > 0
	]).
	directive('consoleText', ['ansiparse', (ansiparse) ->
		restrict: 'E'
		replace: true
		scope: lines: '=consoleTextLines'
		template: '<ol class="prettyConsoleText"></ol>'
		link: (scope, element, attributes) ->
			addLine = (number, line="", linePreviouslyExisted) ->
				ansiParsedLine = ansiparse.parse line
				html = "<span class='prettyConsoleTextLineText textSelectable'>#{ansiParsedLine}</span>"

				if linePreviouslyExisted
					element.find("li:nth-child(#{number})").html html
				else
					element.append '<li>' + html + '</li>'

			handleLinesUpdate = (newValue=[], oldValue=[]) ->
				if newValue.length is 0
					element.empty()
				else
					for line, index in newValue
						if newValue[index] isnt oldValue[index] or index >= oldValue.length
							# It's possible that we get an event for line X although
							# lines [0, x) haven't loaded. When lines [0, x) come in,
							# we want those lines to replace the old lines [0, x),
							# which are null
							replacePrevious = oldValue[index]? or oldValue.length > index
							addLine index+1, line, replacePrevious

			scope.$watch 'lines', handleLinesUpdate, true
	])
	