angular.module('koality.directive.panel', []).
	directive('panel', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<div class="panel" ng-transclude>
				<div class="panelFooter"></div>
			</div>'
	).
	directive('panelHeader', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<div class="panelHeader" unselectable ng-transclude></div>'
		link: (scope, element, attributes) ->
			if attributes.panelHeaderPadding?
				element.addClass 'panelHeaderPadding'
	).
	directive('panelHeaderSubtext', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<div class="panelHeaderSubtext" unselectable ng-transclude></div>'
	).
	directive('panelBody', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<div class="panelBody" ng-transclude></div>'
	)
