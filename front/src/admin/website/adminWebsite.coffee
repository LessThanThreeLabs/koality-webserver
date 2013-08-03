'use strict'

window.AdminWebsite = ['$scope', 'rpc', 'events', 'notification', ($scope, rpc, events, notification) ->
	getWebsiteSettings = () ->
		rpc 'systemSettings', 'read', 'getWebsiteSettings', null, (error, websiteSettings) ->
			$scope.domain = websiteSettings

	$scope.domain = {}
	$scope.ssl = {}
	getWebsiteSettings()

	$scope.submitDomainName = () ->
		rpc 'systemSettings', 'update', 'setWebsiteSettings', $scope.domain, (error) ->
			if error? then notification.error error
			else notification.success 'Updated website domain'

	$scope.submitSslCertificate = () ->
		rpc 'systemSettings', 'update', 'setSslCertificate', $scope.ssl, (error) ->
			if error? then notification.error error
			else notification.success 'Updated website ssl certificates'
]