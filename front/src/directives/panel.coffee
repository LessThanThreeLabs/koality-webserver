angular.module('koality.directive.panel', []).
	directive('panel', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<div class="panel unselectable" ng-transclude>
				<div class="panelFooter"></div>
			</div>'
		link: (scope, element, attributes) ->
			if element.find('.panelOptions').length > 0
				element.addClass 'optionsVisible'
	).
	directive('panelOptions', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<div class="panelOptions" ng-transclude></div>'
	).
	directive('panelOption', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<div class="panelOption" ng-transclude></div>'
		link: (scope, element, attributes) ->
			scope.$watch attributes.selected, (selected=false) ->
				element.toggleClass 'selected', selected
	).
	directive('panelHeader', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<div class="panelHeader" ng-transclude></div>'
		link: (scope, element, attributes) ->
			if attributes.panelHeaderPadding?
				element.addClass 'panelHeaderPadding'
	).
	directive('panelHeaderSubtext', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<div class="panelHeaderSubtext" ng-transclude></div>'
	).
	directive('panelBody', () ->
		restrict: 'E'
		replace: true
		transclude: true
		scope:
			drawerOpen: '='
		template: '<div class="panelBody">
				<div class="panelBodyContents textSelectable" ng-transclude></div>
			</div>'
		link: (scope, element, attributes) ->
			setDrawerState = (open) ->
				panelDrawer = element.find('.panelDrawer')
				panelBodyContents = element.find('.panelBodyContents')

				return if panelDrawer.length is 0 or panelBodyContents.length is 0

				if open then panelBodyContents.css 'top', panelDrawer.outerHeight() + 'px'
				else panelBodyContents.css 'top', '0px'

			moveDrawerOutOfNgTranslate = () ->
				element.append element.find('.panelDrawer')

			moveDrawerOutOfNgTranslate() if element.find('.panelDrawer').length > 0

			scope.$watch 'drawerOpen', (open) ->
				setDrawerState open
	).
	directive('panelDrawer', () ->
		restrict: 'E'
		replace: true
		transclude: true
		template: '<div class="panelDrawer" ng-transclude></div>'
	)
