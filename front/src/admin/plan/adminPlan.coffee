'use strict'

window.AdminPlan = ['$scope', 'rpc', 'notification', ($scope, rpc, notification) ->
	getLicenseKey = () ->
		rpc 'systemSettings', 'read', 'getLicenseKey', null, (error, licenseKey) ->
			$scope.licenseKey = licenseKey

	getLicenseKey()
]
