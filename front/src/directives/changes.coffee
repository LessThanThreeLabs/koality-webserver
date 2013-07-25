angular.module('koality.directive.changes', []).
	directive('changesMenu', () ->
		restrict: 'E'
		require: 'ngModel'
		replace: true
		transclude: true
		template: '<div class="changesMenu unselectable" ng-transclude>
				<div class="changesMenuBackgroundPanel"></div>
				<div class="changesMenuFooter"></div>
			</div>'
	).
	directive('changesMenuHeader', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<div class="changesMenuHeader">
				<div class="changesMenuHeaderContent" ng-transclude></div>
				<div class="changesMenuHeaderBuffer"></div>
			</div>'
		link: (scope, element, attributes) ->
			element.addClass 'noPadding' if attributes.noPadding?
	).
	directive('changesMenuOptions', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<div class="changesMenuOptions">
				<div class="changesMenuOptionsScrollOuterWrapper">
					<div class="changesMenuOptionsScrollInnerWrapper" ng-transclude></div>
				</div>
			</div>'
		link: (scope, element, attributes) ->
			addScrollListener = () ->
				outerElement = element.find('.changesMenuOptionsScrollOuterWrapper')
				outerElement.bind 'scroll', (event) ->
					scrolledToBottom = outerElement[0].scrollTop + outerElement[0].offsetHeight >= outerElement[0].scrollHeight
					scope.$apply attributes.onScrollToBottom if scrolledToBottom

			addScrollListener() if attributes.onScrollToBottom?
	).
	directive('changesMenuOption', () ->
		restrict: 'E'
		replace: true
		scope: true
		template: '<div class="changesMenuOption">
				<div class="changesMenuOptionContents">
					<div class="changesMenuOptionTextContainer">
						<span class="changesMenuOptionIdentifier">{{identifier}}</span>
						<span class="changesMenuOptionText">{{text}}</span>
					</div>
					<div class="changesMenuOptionArrow"></div>
					<spinner class="changesMenuOptionSpinner" spinner-running="spinning"></spinner>
				</div>
				<div class="changesMenuOptionTooth"></div>
			</div>'
		link: (scope, element, attributes) ->
			checkOffsetTextClass = () ->
				if scope.identifier? and scope.text? then element.find('.changesMenuOptionContents').addClass 'offsetText'
				else element.find('.changesMenuOptionContents').removeClass 'offsetText'

			attributes.$observe 'menuOptionIdentifier', (identifier) ->
				scope.identifier = identifier
				checkOffsetTextClass()

			attributes.$observe 'menuOptionText', (text) ->
				scope.text = text
				checkOffsetTextClass()

			attributes.$observe 'menuOptionSpinning', (spinning) ->
				scope.spinning = if typeof spinning is 'boolean' then spinning else spinning is 'true'

			scope.$watch 'spinning', (newValue, oldValue) ->
				element.find('.changesMenuOptionTextContainer').toggleClass 'spinnerTextPadding', scope.spinning
	)