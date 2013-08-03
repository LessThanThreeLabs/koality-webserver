'use strict'

window.AdminExporter = ['$scope', 'rpc', 'notification', ($scope, rpc, notification) ->
	getS3BucketName = () ->
		rpc 'systemSettings', 'read', 'getS3BucketName', null, (error, bucketName) ->
			$scope.exporter.s3BucketName = bucketName

	$scope.exporter = {}
	getS3BucketName()

	$scope.submit = () ->
		rpc 'systemSettings', 'update', 'setS3BucketName', bucketName: $scope.exporter.s3BucketName, (error) ->
			if error? then notification.error error
			else notification.success 'Updated exporter settings'
]
