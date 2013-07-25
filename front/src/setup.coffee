'use strict'

angular.module('koality', ['ngSanitize', 'koality.service', 'koality.filter',
		'koality.directive', 'koality.directive.changes', 'koality.directive.panel', 'koality.d3.directive']).
	config(['$routeProvider', ($routeProvider) ->
		$routeProvider.
			when('/login',
				templateUrl: "/html/login#{fileSuffix}.html"
				controller: Login
				redirectTo: if window.accountInformation.id is '' then null else '/'
			).
			when('/account',
				templateUrl: "/html/account#{fileSuffix}.html"
				controller: Account
				reloadOnSearch: false
				redirectTo: if window.accountInformation.id is '' then '/login' else null
			).
			when('/create/account',
				templateUrl: "/html/createAccount#{fileSuffix}.html"
				controller: CreateAccount
				reloadOnSearch: false
				redirectTo: if window.accountInformation.id is '' then null else '/'
			).
			when('/resetPassword',
				templateUrl: "/html/resetPassword#{fileSuffix}.html"
				controller: ResetPassword
				redirectTo: if window.accountInformation.id is '' then null else '/'
			).
			when('/repository/:repositoryId',
				templateUrl: "/html/repository/repository#{fileSuffix}.html"
				controller: Repository
				reloadOnSearch: false
				redirectTo: if window.accountInformation.id is '' then '/login' else null
			).
			when('/',
				templateUrl: "/html/analytics#{fileSuffix}.html"
				controller: Analytics
				reloadOnSearch: false
				redirectTo: if window.accountInformation.id is '' then '/login' else null
			).
			when('/admin',
				templateUrl: "/html/admin#{fileSuffix}.html"
				controller: Admin
				reloadOnSearch: false
				redirectTo: if window.accountInformation.isAdmin then null else '/'
			).
			otherwise(
				redirectTo: '/'
			)
	]).
	config(['$locationProvider', ($locationProvider) ->
		$locationProvider.html5Mode true
	]).
	run(() ->
		# initialization happens here
	)
