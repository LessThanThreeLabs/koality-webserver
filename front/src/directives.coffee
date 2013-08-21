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
				<div class="fadingContentScrollWrapper onScrollToTopDirectiveAnchor onScrollToBottomDirectiveAnchor autoScrollToBottomDirectiveAnchor onScrollToBottomDirectiveAnchor">
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
				isFirstRender = () ->
					return not oldValue? or oldValue.length is 0 or Object.keys(oldValue).length is 0

				if isFirstRender()
					scrollToBottom() if attributes.startAtBottom?
				else
					isScrolledToBottomIsh = element[0].scrollTop + element[0].offsetHeight + scrollBottomBuffer >= element[0].scrollHeight
					scrollToBottom() if isScrolledToBottomIsh
			), true
	]).
	directive('onScrollToTop', [() ->
		restrict: 'A'
		link: (scope, element, attributes) ->
			if element.find('.onScrollToTopDirectiveAnchor').length > 0
				element = element.find '.onScrollToTopDirectiveAnchor'

			addScrollListener = () ->
				element.bind 'scroll', (event) ->
					scrolledToTop = element[0].scrollTop is 0
					scope.$apply attributes.onScrollToTop if scrolledToTop

			addScrollListener()
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
				<spinner white running="busy" class="busyButtonSpinner"></spinner>
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
		scope: running: '=running'
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

			scope.$watch 'running', () ->
				if scope.running then startSpinner() else stopSpinner()

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
		scope: lines: '=lines'
		template: '<ol class="prettyConsoleText"></ol>'
		link: (scope, element, attributes) ->
			lineNumberBounds = null

			getLineNumberBounds = (lines) ->
				return null if Object.keys(lines).length is 0

				minLineNumber = Number.MAX_VALUE
				maxLineNumber = Number.MIN_VALUE

				for lineNumber in Object.keys lines
					minLineNumber = Math.min minLineNumber, lineNumber
					maxLineNumber = Math.max maxLineNumber, lineNumber

				return {min: minLineNumber, max: maxLineNumber}

			setStartingNumber = (number) ->
				element.css 'counter-reset', 'item ' + (number - 1)

			clearLines = () ->
				lineNumberBounds = null
				element.empty()
				setStartingNumber 1

			renderInitialLines = (lines) ->
				lineNumberBounds = getLineNumberBounds lines
				return if not lineNumberBounds?

				setStartingNumber lineNumberBounds.min

				for index in [lineNumberBounds.min..lineNumberBounds.max]
					ansiParsedLine = ansiparse.parse lines[index].text
					html = "<span class='prettyConsoleTextLineText' number=#{index}>#{ansiParsedLine}</span>"
					element.append "<li>#{html}</li>"

			updateLines = (newLines, oldLines) ->
				newLineNumberBounds = getLineNumberBounds newLines
				setStartingNumber newLineNumberBounds.min

				addLinesThatAreBeforeExistingLines = () ->
					return if newLineNumberBounds.min >= lineNumberBounds.min

					for index in [newLineNumberBounds.min...lineNumberBounds.min]
						ansiParsedLine = ansiparse.parse newLines[index]?.text ? ''
						html = "<span class='prettyConsoleTextLineText' number=#{index}>#{ansiParsedLine}</span>"

						if index is newLineNumberBounds.min
							element.prepend "<li>#{html}</li>"
						else
							previousChildIndex = index - newLineNumberBounds.min
							element.find("li:nth-child(#{previousChildIndex})").after "<li>#{html}</li>"

				updateLinesThatAlreadyExist = () ->
					for index in [lineNumberBounds.min..lineNumberBounds.max]
						continue if oldLines[index]?.hash? and oldLines[index]?.hash is newLines[index]?.hash

						ansiParsedLine = ansiparse.parse newLines[index]?.text ? ''
						element.find(".prettyConsoleTextLineText[number='#{index}']").html ansiParsedLine

				addLinesThatAreAfterExistingLines = () ->
					return if newLineNumberBounds.max <= lineNumberBounds.max

					for index in [(lineNumberBounds.max + 1)..newLineNumberBounds.max]
						ansiParsedLine = ansiparse.parse newLines[index]?.text ? ''
						html = "<span class='prettyConsoleTextLineText' number=#{index}>#{ansiParsedLine}</span>"
						element.append "<li>#{html}</li>"

				addLinesThatAreBeforeExistingLines()
				updateLinesThatAlreadyExist()
				addLinesThatAreAfterExistingLines()

				lineNumberBounds = newLineNumberBounds

			handleLinesUpdate = (newValue=[], oldValue=[]) ->
				if Object.keys(newValue).length is 0
					clearLines()
				else if Object.keys(oldValue).length is 0
					renderInitialLines newValue
				else
					updateLines newValue, oldValue

			scope.$watch 'lines', handleLinesUpdate, true
	])
	