'use strict'

window.Admin = ['$scope', '$location', '$routeParams', 'initialState', ($scope, $location, $routeParams, initialState) ->
	$scope.userId = initialState.user.id
	$scope.currentView = $routeParams.view ? 'website'

	$scope.menuOptionClick = (viewName) ->
		$scope.currentView = viewName

	$scope.$watch 'currentView', (newValue, oldValue) ->
		$location.search 'view', newValue
]


window.AdminWebsite = ['$scope', 'rpc', 'events', 'notification', ($scope, rpc, events, notification) ->
	getWebsiteSettings = () ->
		rpc.makeRequest 'systemSettings', 'read', 'getWebsiteSettings', null, (error, websiteSettings) ->
			$scope.$apply () -> $scope.website = websiteSettings

	$scope.website = {}
	getWebsiteSettings()

	$scope.submit = () ->
		rpc.makeRequest 'systemSettings', 'update', 'setWebsiteSettings', $scope.website, (error) ->
			if error? then notification.error 'Unable to update website domain'
			else notification.success 'Updated website domain'
]


window.AdminUsers = ['$scope', 'initialState', 'rpc', 'events', 'notification', ($scope, initialState, rpc, events, notification) ->
	$scope.orderByPredicate = 'lastName'
	$scope.orderByReverse = false

	$scope.addUsers = {}
	$scope.addUsers.modalVisible = false

	getUsers = () ->
		rpc.makeRequest 'users', 'read', 'getAllUsers', null, (error, users) ->
			$scope.$apply () -> $scope.users = users

	inviteUsers = () ->
		rpc.makeRequest 'users', 'create', 'inviteUsers', emails: $scope.addUsers.emails, (error) ->
			$scope.$apply () ->
				if error? then $scope.addUsers.showError = true
				else
					notification.success 'Invited new users'
					$scope.addUsers.modalVisible = false
					$scope.addUsers.showError = false
					$scope.addUsers.emails = ''

	handleUserAdded = (data) -> $scope.$apply () ->
		$scope.users.push data

	handleUserRemoved = (data) -> $scope.$apply () ->
		userToRemoveIndex = (index for user, index in $scope.users when user.id is data.id)[0]
		$scope.users.splice userToRemoveIndex, 1 if userToRemoveIndex?

	addUserEvents = events.listen('users', 'user created', initialState.user.id).setCallback(handleUserAdded).subscribe()
	removeUserEvents = events.listen('users', 'user removed', initialState.user.id).setCallback(handleUserRemoved).subscribe()
	$scope.$on '$destroy', addUserEvents.unsubscribe
	$scope.$on '$destroy', removeUserEvents.unsubscribe

	getUsers()

	$scope.removeUser = (user) ->
		rpc.makeRequest 'users', 'delete', 'deleteUser', id: user.id, (error) ->
			if error? then notification.error 'Unable to delete user ' + user.email

	$scope.submitEmails = () ->
		inviteUsers()
]


window.AdminRepositories = ['$scope', '$location', '$routeParams', 'initialState', 'rpc', 'events', 'notification', ($scope, $location, $routeParams, initialState, rpc, events, notification) ->
	$scope.orderByPredicate = 'name'
	$scope.orderByReverse = false

	$scope.addRepository = {}
	$scope.addRepository.stage = 'first'
	$scope.addRepository.modalVisible = false

	$scope.removeRepository = {}
	$scope.removeRepository.modalVisible = false

	$scope.publicKey = {}
	$scope.publicKey.modalVisible = false

	$scope.forwardUrl = {}
	$scope.forwardUrl.modalVisible = false

	$scope.$on '$routeUpdate', () -> showRepositoriesLimitWarningIfNecessary()

	getRepositories = () ->
		rpc.makeRequest 'repositories', 'read', 'getRepositories', null, (error, repositories) ->
			$scope.$apply () ->
				$scope.repositories = repositories

	getMaxRepositoryCount = () ->
		rpc.makeRequest 'systemSettings', 'read', 'getMaxRepositoryCount', null, (error, maxRepositoryCount) ->
			$scope.$apply () ->
				$scope.maxRepositoryCount = maxRepositoryCount ? Number.POSITIVE_INFINITY
				showRepositoriesLimitWarningIfNecessary()

	showRepositoriesLimitWarningIfNecessary = () ->
		if $routeParams.view is 'repositories' and $scope.repositories.length >= $scope.maxRepositoryCount
			notification.warning 'Max number of repositories reached. Upgrade to increase this limit.'

	handleAddedRepositoryUpdate = (data) -> $scope.$apply () ->
		$scope.repositories.push data

	handleRemovedRepositoryUpdate = (data) -> $scope.$apply () ->
		repositoryToRemoveIndex = (index for repository, index in $scope.repositories when repository.id is data.id)[0]
		$scope.repositories.splice repositoryToRemoveIndex, 1 if repositoryToRemoveIndex?

	addRepositoryEvents = events.listen('users', 'repository added', initialState.user.id).setCallback(handleAddedRepositoryUpdate).subscribe()
	removeRepositoryEvents = events.listen('users', 'repository removed', initialState.user.id).setCallback(handleRemovedRepositoryUpdate).subscribe()
	$scope.$on '$destroy', addRepositoryEvents.unsubscribe
	$scope.$on '$destroy', removeRepositoryEvents.unsubscribe

	getRepositories()
	getMaxRepositoryCount()

	$scope.openRemoveRepository = (repository) ->
		$scope.removeRepository.id = repository.id
		$scope.removeRepository.name = repository.name
		$scope.removeRepository.tokenToMatch = Math.random().toString(36).substr(2)
		$scope.removeRepository.modalVisible = true

	$scope.submitRemoveRepository = () ->
		return if $scope.removeRepository.token isnt $scope.removeRepository.tokenToMatch

		requestParams =
			id: $scope.removeRepository.id
			password: $scope.removeRepository.password
		rpc.makeRequest 'repositories', 'delete', 'deleteRepository', requestParams, (error) ->
			if error? then notification.error 'Unable to remove repository'
			else
				$scope.$apply () ->
					$scope.removeRepository.modalVisible = false

	$scope.getSshKey = () ->
		rpc.makeRequest 'repositories', 'create', 'getSshPublicKey', $scope.addRepository, (error, sshPublicKey) ->
			$scope.$apply () ->
				$scope.addRepository.publicKey = sshPublicKey
				$scope.addRepository.stage = 'second'

	$scope.createRepository = () ->
		rpc.makeRequest 'repositories', 'create', 'createRepository', $scope.addRepository, (error, repositoryId) ->
			if error? then notification.error 'Unable to create repository'
			else
				notification.success 'Created repository ' + $scope.addRepository.name
				$scope.$apply () ->
					$scope.addRepository.modalVisible = false

	resetAddRepositoryValues = () ->
		$scope.addRepository.stage = 'first'
		$scope.addRepository.name = null
		$scope.addRepository.forwardUrl = null
		$scope.addRepository.publicKey = null

	resetRemoveRepositoryValues = () ->
		$scope.removeRepository.showError = false
		$scope.removeRepository.token = ''
		$scope.removeRepository.password = ''

	$scope.showPublicKey = (repository) ->
		rpc.makeRequest 'repositories', 'read', 'getPublicKey', id: repository.id, (error, publicKey) ->
			$scope.$apply () ->
				$scope.publicKey.key = publicKey
				$scope.publicKey.modalVisible = true

	$scope.showForwardUrl = (repository) ->
		rpc.makeRequest 'repositories', 'read', 'getForwardUrl', id: repository.id, (error, forwardUrl) ->
			$scope.$apply () ->
				$scope.forwardUrl.id = repository.id
				$scope.forwardUrl.url = forwardUrl
				$scope.forwardUrl.modalVisible = true

	$scope.editForwardUrl = () ->
		requestParams =
			id: $scope.forwardUrl.id
			forwardUrl: $scope.forwardUrl.url
		rpc.makeRequest 'repositories', 'update', 'setForwardUrl', requestParams, (error, forwardUrl) ->
			if error? then notification.error 'Unable to update forward url'
			else 
				notification.success 'Updated forward url'
				$scope.$apply () ->
					$scope.forwardUrl.modalVisible = false

	$scope.$watch 'addRepository.modalVisible', (newValue, oldValue) ->
		resetAddRepositoryValues() if not newValue

	$scope.$watch 'removeRepository.modalVisible', (newValue, oldValue) ->
		resetRemoveRepositoryValues() if not newValue
]


window.AdminAws = ['$scope', 'rpc', 'notification', ($scope, rpc, notification) ->
	getAwsKeys = () ->
		rpc.makeRequest 'systemSettings', 'read', 'getAwsKeys', null, (error, awsKeys) ->
			$scope.$apply () ->
				$scope.awsKeys = awsKeys

	getAllowedInstanceSizes = () ->
		rpc.makeRequest 'systemSettings', 'read', 'getAllowedInstanceSizes', null, (error, allowedInstanceSizes) ->
			$scope.$apply () ->
				$scope.allowedInstanceSizes = allowedInstanceSizes

	getInstanceSettings = () ->
		rpc.makeRequest 'systemSettings', 'read', 'getInstanceSettings', null, (error, instanceSettings) ->
			$scope.$apply () ->
				$scope.instanceSettings = instanceSettings

	getAwsKeys()
	getAllowedInstanceSizes()
	getInstanceSettings()

	$scope.submit = () ->
		await
			rpc.makeRequest 'systemSettings', 'update', 'setAwsKeys', $scope.awsKeys, defer awsKeysError
			rpc.makeRequest 'systemSettings', 'update', 'setInstanceSettings', $scope.instanceSettings, defer instanceSettingsError

		if awsKeysError then notification.error 'Unable to update aws keys'
		else if instanceSettingsError then notification.error 'Unable to update aws instance information'
		else notification.success 'Updated aws information'
]


window.AdminExporter = ['$scope', 'rpc', 'notification', ($scope, rpc, notification) ->
	getS3BucketName = () ->
		rpc.makeRequest 'systemSettings', 'read', 'getS3BucketName', null, (error, bucketName) ->
			$scope.$apply () -> $scope.exporter.s3bucketName = bucketName

	$scope.exporter = {}
	getS3BucketName()

	$scope.submit = () ->
		rpc.makeRequest 'systemSettings', 'update', 'setS3BucketName', bucketName: $scope.exporter.s3bucketName, (error) ->
			if error? then notification.error 'Unable to update exporter settings'
			else notification.success 'Updated exporter settings'
]

window.AdminApi = ['$scope', 'rpc', ($scope, rpc) ->
	getApiKey = () ->
		rpc.makeRequest 'systemSettings', 'read', 'getAdminApiKey', null, (error, apiKey) ->
			$scope.$apply () ->
				$scope.apiKey = apiKey

	getDomainName = () ->
		rpc.makeRequest 'systemSettings', 'read', 'getWebsiteSettings', null, (error, websiteSettings) ->
			$scope.$apply () ->
				$scope.domainName = websiteSettings.domainName

	$scope.regenerateKey = () ->
		rpc.makeRequest 'systemSettings', 'update', 'regenerateApiKey', null, (error, apiKey) ->
			$scope.$apply () ->
				$scope.apiKey = apiKey

	getApiKey()
	getDomainName()
]


window.AdminUpgrade = ['$scope', 'initialState', 'rpc', 'events', ($scope, initialState, rpc, events) ->
	$scope.upgrade = {}
	$scope.upgrade.spinnerOn = true

	getUpgradeStatus = () ->
		rpc.makeRequest 'systemSettings', 'read', 'getUpgradeStatus', null, (error, upgradeStatus) ->
			$scope.$apply () ->
				$scope.upgrade.spinnerOn = false
				handleUpgradeStatus upgradeStatus

	handleUpgradeStatus = (upgradeStatus) ->
		lastUpgradeStatus = upgradeStatus.lastUpgradeStatus
		upgradeAvailable = upgradeStatus.upgradeAvailable ? false
		if lastUpgradeStatus is 'running'
			$scope.upgrade.message = 'An upgrade is currently in progress. ' +
				'You should expect the system to restart in a few minutes.'
			$scope.upgrade.upgradeAllowed = false
		else if lastUpgradeStatus is 'failed'
			$scope.upgrade.message = 'The last upgrade failed. Contact support if this happens again.'
			$scope.upgrade.upgradeAllowed = upgradeAvailable
		else if upgradeAvailable
			$scope.upgrade.message = 'An upgrade to Koality is available. ' +
				'Upgrading will shut down the server and may take several minutes before restarting.'
			$scope.upgrade.upgradeAllowed = true
		else
			$scope.upgrade.message = 'There are no upgrades available at this time.'
			$scope.upgrade.upgradeAllowed = false

	handleSystemSettingsUpdate = (data) -> $scope.$apply () ->
		if data.resource is 'deployment' and data.key is 'upgrade_status'
			handleUpgradeStatus { lastUpgradeStatus: data.value }

	changedSystemSetting = events.listen('systemSettings', 'system setting updated', initialState.user.id).setCallback(handleSystemSettingsUpdate).subscribe()
	$scope.$on '$destroy', changedSystemSetting.unsubscribe

	getUpgradeStatus()

	$scope.performUpgrade = () ->
		$scope.upgrade.upgradeAllowed = false
		rpc.makeRequest 'systemSettings', 'update', 'upgradeDeployment', null
]
