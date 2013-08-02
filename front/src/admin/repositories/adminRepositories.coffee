'use strict'

window.AdminRepositories = ['$scope', '$routeParams', 'initialState', 'rpc', 'events', 'notification', ($scope, $routeParams, initialState, rpc, events, notification) ->
	$scope.orderByPredicate = 'name'
	$scope.orderByReverse = false

	$scope.addRepository =
		makingRequest: false
		drawerOpen: false

	getRepositories = () ->
		rpc 'repositories', 'read', 'getRepositoriesWithForwardUrls', null, (error, repositories) ->
			console.log repositories
			$scope.repositories = repositories	

	getMaxRepositoryCount = () ->
		rpc 'systemSettings', 'read', 'getMaxRepositoryCount', null, (error, maxRepositoryCount) ->
			$scope.maxRepositoryCount = maxRepositoryCount ? Number.POSITIVE_INFINITY
			showRepositoriesLimitWarningIfNecessary()

	showRepositoriesLimitWarningIfNecessary = () ->
		upgradeUrl = 'https://koalitycode.com/account/plan'
		if $routeParams.view is 'repositories' and $scope.repositories.length >= $scope.maxRepositoryCount
			notification.warning "Max number of repositories reached. <a href='#{upgradeUrl}'>Upgrade to increase this limit</a>"

	handleAddedRepositoryUpdate = (data) ->
		$scope.repositories.push data

	handleRemovedRepositoryUpdate = (data) ->
		repositoryToRemoveIndex = (index for repository, index in $scope.repositories when repository.id is data.id)[0]
		$scope.repositories.splice repositoryToRemoveIndex, 1 if repositoryToRemoveIndex?

	addRepositoryEvents = events('users', 'repository added', initialState.user.id).setCallback(handleAddedRepositoryUpdate).subscribe()
	removeRepositoryEvents = events('users', 'repository removed', initialState.user.id).setCallback(handleRemovedRepositoryUpdate).subscribe()
	$scope.$on '$destroy', addRepositoryEvents.unsubscribe
	$scope.$on '$destroy', removeRepositoryEvents.unsubscribe

	getRepositories()
	getMaxRepositoryCount()

	# $scope.removeUser = (user) ->
	# 	rpc 'users', 'delete', 'deleteUser', id: user.id, (error) ->
	# 		if error? then notification.error 'Unable to delete user ' + user.email

	# $scope.submitUsers = () ->
	# 	return if $scope.addUsers.makingRequest
	# 	$scope.addUsers.makingRequest = true

	# 	rpc 'users', 'create', 'inviteUsers', emails: $scope.addUsers.emails, (error) ->
	# 		$scope.addUsers.makingRequest = false
	# 		if error? then notification.error error
	# 		else 
	# 			notification.success 'Invited new users'
	# 			$scope.clearAddUsers()

	$scope.clearAddReposity = () ->
		# $scope.addRepository.emails = ''
		$scope.addRepository.drawerOpen = false
]




# $scope.orderByPredicate = 'name'
# 	$scope.orderByReverse = false

# 	$scope.addRepository = {}
# 	$scope.addRepository.stage = 'first'
# 	$scope.addRepository.modalVisible = false
# 	$scope.addRepository.type = 'git'

# 	$scope.removeRepository = {}
# 	$scope.removeRepository.modalVisible = false

# 	$scope.publicKey = {}
# 	$scope.publicKey.modalVisible = false

# 	$scope.forwardUrl = {}
# 	$scope.forwardUrl.modalVisible = false

# 	$scope.$on '$routeUpdate', () -> showRepositoriesLimitWarningIfNecessary()

# 	getRepositories = () ->
# 		rpc 'repositories', 'read', 'getRepositories', null, (error, repositories) ->
# 			$scope.repositories = repositories

# 	getMaxRepositoryCount = () ->
# 		rpc 'systemSettings', 'read', 'getMaxRepositoryCount', null, (error, maxRepositoryCount) ->
# 			$scope.maxRepositoryCount = maxRepositoryCount ? Number.POSITIVE_INFINITY
# 			showRepositoriesLimitWarningIfNecessary()

# 	showRepositoriesLimitWarningIfNecessary = () ->
# 		upgradeUrl = 'https://koalitycode.com/account/plan'
# 		if $routeParams.view is 'repositories' and $scope.repositories.length >= $scope.maxRepositoryCount
# 			notification.warning "Max number of repositories reached. <a href='#{upgradeUrl}'>Upgrade to increase this limit</a>"

# 	handleAddedRepositoryUpdate = (data) ->
# 		$scope.repositories.push data

# 	handleRemovedRepositoryUpdate = (data) ->
# 		repositoryToRemoveIndex = (index for repository, index in $scope.repositories when repository.id is data.id)[0]
# 		$scope.repositories.splice repositoryToRemoveIndex, 1 if repositoryToRemoveIndex?

# 	addRepositoryEvents = events('users', 'repository added', initialState.user.id).setCallback(handleAddedRepositoryUpdate).subscribe()
# 	removeRepositoryEvents = events('users', 'repository removed', initialState.user.id).setCallback(handleRemovedRepositoryUpdate).subscribe()
# 	$scope.$on '$destroy', addRepositoryEvents.unsubscribe
# 	$scope.$on '$destroy', removeRepositoryEvents.unsubscribe

# 	getRepositories()
# 	getMaxRepositoryCount()

# 	$scope.openRemoveRepository = (repository) ->
# 		$scope.removeRepository.id = repository.id
# 		$scope.removeRepository.name = repository.name
# 		$scope.removeRepository.tokenToMatch = Math.random().toString(36).substr(2)
# 		$scope.removeRepository.modalVisible = true

# 	$scope.submitRemoveRepository = () ->
# 		return if $scope.removeRepository.token isnt $scope.removeRepository.tokenToMatch

# 		requestParams =
# 			id: $scope.removeRepository.id
# 			password: $scope.removeRepository.password
# 		rpc 'repositories', 'delete', 'deleteRepository', requestParams, (error) ->
# 			if error? then notification.error 'Unable to remove repository'
# 			else
# 				$scope.removeRepository.modalVisible = false

# 	$scope.getSshKey = () ->
# 		rpc 'repositories', 'create', 'getSshPublicKey', $scope.addRepository, (error, sshPublicKey) ->
# 			$scope.addRepository.publicKey = sshPublicKey
# 			$scope.addRepository.stage = 'second'

# 	$scope.createRepository = () ->
# 		rpc 'repositories', 'create', 'createRepository', $scope.addRepository, (error, repositoryId) ->
# 			if error is 'Repository already exists'
# 				notification.error 'Repository already exists'
# 				$scope.addRepository.modalVisible = false
# 			else if error? then notification.error 'Unable to create repository'
# 			else
# 				notification.success 'Created repository ' + $scope.addRepository.name
# 				$scope.addRepository.modalVisible = false

# 	resetAddRepositoryValues = () ->
# 		$scope.addRepository.stage = 'first'
# 		$scope.addRepository.name = null
# 		$scope.addRepository.forwardUrl = null
# 		$scope.addRepository.publicKey = null
# 		$scope.addRepository.type = 'git'

# 	resetRemoveRepositoryValues = () ->
# 		$scope.removeRepository.showError = false
# 		$scope.removeRepository.token = ''
# 		$scope.removeRepository.password = ''