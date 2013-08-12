'use strict'

angular.module('koalitySetup', ['ngSanitize', 'koality.service', 'koality.directive', 'koality.filter']).
	config(['$routeProvider', ($routeProvider) ->
		$routeProvider.
			when('/wizard',
				templateUrl: "/html/installationWizard/wizard/wizard#{fileSuffix}.html"
				controller: Wizard
				reloadOnSearch: false
			).
			otherwise(
				redirectTo: '/wizard'
			)
	]).
	config(['$locationProvider', ($locationProvider) ->
		$locationProvider.html5Mode true
	]).
	run(() ->
		# initialization happens here
	)
