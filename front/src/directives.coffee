'use strict'

angular.module('koality.directive', []).
	directive('highlightOnFirstClick', () ->
		return (scope, element, attributes) ->
			highlightText = () ->
				element.select()
				element.unbind 'click', highlightText

			element.bind 'click', highlightText
	).
	directive('focused', () ->
		return (scope, element, attributes) ->
			element.focus()
	).
	directive('inputFocusOnClick', () ->
		return (scope, element, attributes) ->
			element.bind 'click', (event) ->
				element.find('input').focus()
	).
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
	directive('divider', () ->
		restrict: 'E'
		replace: true
		template: '<div class="prettyDivider"></div>'
	).
	directive('dropdownContainer', ['$timeout', ($timeout) ->
		restrict: 'A'
		link: (scope, element, attributes) ->
			element.addClass 'prettyDropdownContainer'
	]).
	directive('dropdown', ['$document', '$timeout', ($document, $timeout) ->
		restrict: 'E'
		replace: true
		scope:
			alignment: '@dropdownAlignment'
			options: '=dropdownOptions'
			clickHandler: '&dropdownOptionClick'
		template: '<div class="prettyDropdown {{alignment}}Aligned">
				<div class="prettyDropdownOption" ng-repeat="option in options | orderBy:\'title\'" ng-click="clickHandler({dropdownOption: option.name}); hideDropdown()">{{option.title}}</div>
				<div class="prettyDropdownOption" ng-show="options.length == 0">-- empty --</div>
			</div>'
		link: (scope, element, attributes) ->
			removeTemporaryHideWindowListener = () ->
				element.removeClass 'temporaryHide'
				$document.unbind 'mousemove', removeTemporaryHideWindowListener

			scope.hideDropdown = () ->
				element.addClass 'temporaryHide'
				$document.bind 'mousemove', removeTemporaryHideWindowListener
	]).
	directive('autoScrollToBottom', ['integerConverter', (integerConverter) ->
		restrict: 'A'
		link: (scope, element, attributes) ->
			scrollToBottom = () ->
				element[0].scrollTop = element[0].scrollHeight

			scrollBottomBuffer = integerConverter.toInteger(attributes.autoScrollToBottomBuffer) ? 20

			scope.$watch attributes.autoScrollToBottom, ((newValue, oldValue) ->
				return if oldValue.length is 0
				isScrolledToBottomIsh = element[0].scrollTop + element[0].offsetHeight + scrollBottomBuffer >= element[0].scrollHeight
				setTimeout scrollToBottom, 0 if isScrolledToBottomIsh
			), true
	]).
	directive('busyButton', () ->
		restrict: 'E'
		replace: true
		transclude: true
		scope:
			show: '=show'
			busy: '=busy'
			disabled: '=disabled'
			click: '&click'
		template: '<div ng-show="(show != null && show) || (show == null)">
				<button ng-show="!busy" ng-click="click()" ng-disabled="disabled" ng-transclude></button>
				<spinner white spinner-running="busy" class="busyButtonSpinner"></spinner>
			</div>'
		link: (scope, element, attributes) ->
			element.css
				position: 'relative'
				'z-index': 1

			button = element.find 'button'
			button.addClass 'centered' if attributes.centered?
			button.addClass 'fullWidth' if attributes.fullWidth?

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
	).
	directive('modal', ['$document', ($document) ->
		restrict: 'E'
		replace: true
		transclude: true
		scope: show: '=modalVisible'
		template: '<div class="prettyModal" ng-class="{visible: show}">
				<div class="prettyModalBackdrop" ng-click="show=false"></div>
				<div class="prettyModalContent" ng-transclude></div>
			</div>'
		link: (scope, element, attributes) ->
			escapeClickHandler = (event) ->
				if event.keyCode is 27
					scope.$apply () -> scope.show = false

			scope.$watch 'show', () ->
				if scope.show
					$document.bind 'keydown', escapeClickHandler
					setTimeout (() ->
						firstInput = element.find('input,textarea,select').get(0)
						firstInput.focus() if firstInput?
					), 0
				else
					$document.unbind 'keydown', escapeClickHandler
	]).
	directive('tooltip', () ->
		restrict: 'A'
		link: (scope, element, attributes) ->
			html = "<span class='prettyTooltipContainer'>
					<span class='prettyTooltipCenterAnchor'>
						<span class='prettyTooltipCenterContainer'>
							<span class='prettyTooltip'>#{attributes.tooltip}</span>
						</span>
					</span>
				</span>"
			element.append html
	).
	directive('notification', () ->
		restrict: 'E'
		replace: true
		transclude: true
		scope:
			type: '@'
			durationInSeconds: '@'
		template: '<div class="prettyNotification" ng-class="{green: type == \'success\', orange: type == \'warning\', red: type == \'error\'}">
					<div class="prettyNotificationContent growingCentered">
						<span ng-transclude></span>
						<span class="prettyNotificationClose" ng-click="hide()">X</span>
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
				setTimeout (() -> element.remove()), 5000

			element.css 'z-index', getZIndex attributes.type, attributes.durationInSeconds > 0
			setTimeout scope.hide, attributes.durationInSeconds * 1000 if attributes.durationInSeconds > 0
	).
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

			handleLinesUpdate = (newValue, oldValue) ->
				if not newValue? or newValue.length is 0
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
	