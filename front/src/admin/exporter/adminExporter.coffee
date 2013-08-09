'use strict'

window.AdminExporter = ['$scope', 'rpc', 'notification', ($scope, rpc, notification) ->
	$scope.makingRequest = false

	getS3BucketName = () ->
		rpc 'systemSettings', 'read', 'getS3BucketName', null, (error, bucketName) ->
			$scope.exporter.s3BucketName = bucketName

	$scope.exporter = {}
	getS3BucketName()

	$scope.submit = () ->
		return if $scope.makingRequest
		$scope.makingRequest = true

		rpc 'systemSettings', 'update', 'setS3BucketName', bucketName: $scope.exporter.s3BucketName, (error) ->
			$scope.makingRequest = false
			if error? then notification.error error
			else notification.success 'Updated exporter settings'
]
