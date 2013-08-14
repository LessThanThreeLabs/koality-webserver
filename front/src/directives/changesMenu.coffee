angular.module('koality.directive.changesMenu', []).
	directive('changesMenu', () ->
		restrict: 'E'
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
				<div class="changesMenuOptionsScrollWrapper" ng-transclude></div>
			</div>'
		link: (scope, element, attributes) ->
			addScrollListener = () ->
				outerElement = element.find('.changesMenuOptionsScrollWrapper')
				outerElement.bind 'scroll', (event) ->
					scrolledToBottom = outerElement[0].scrollTop + outerElement[0].offsetHeight >= outerElement[0].scrollHeight
					scope.$apply attributes.onScrollToBottom if scrolledToBottom

			addScrollListener() if attributes.onScrollToBottom?
	).
	directive('changesMenuEmptyMessage', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<div class="changesMenuEmptyMessage" ng-transclude></div>'
	).
	directive('changesMenuOption', () ->
		restrict: 'E'
		replace: true
		scope: true
		template: '<div class="changesMenuOption">
				<div class="changesMenuOptionContents">
					<div class="changesMenuOptionTextContainer">
						<span class="changesMenuOptionIdentifier" ng-show="identifier != null">{{identifier}}</span>
						<span class="changesMenuOptionText" ng-show="text != null">{{text}}</span>
					</div>
					<div class="changesMenuOptionArrow"></div>
					<spinner class="changesMenuOptionSpinner" spinner-running="spinning"></spinner>
				</div>
				<div class="changesMenuOptionTooth"></div>
			</div>'
		link: (scope, element, attributes) ->
			attributes.$observe 'menuOptionIdentifier', (identifier) ->
				scope.identifier = identifier

			attributes.$observe 'menuOptionText', (text) ->
				scope.text = text

			attributes.$observe 'menuOptionSpinning', (spinning) ->
				scope.spinning = if typeof spinning is 'boolean' then spinning else spinning is 'true'

			scope.$watch 'spinning', (newValue, oldValue) ->
				element.find('.changesMenuOptionTextContainer').toggleClass 'spinnerTextPadding', scope.spinning
	)