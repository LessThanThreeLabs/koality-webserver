'use strict'

window.AdminRepositories = ['$scope', '$routeParams', 'initialState', 'rpc', 'events', 'notification', ($scope, $routeParams, initialState, rpc, events, notification) ->
	$scope.orderByPredicate = 'name'
	$scope.orderByReverse = false

	$scope.currentlyEditingRepositoryId = null
	$scope.currentlyOpenDrawer = null

	$scope.addRepository =
		setupType: 'manual'
		manual: {}
		gitHub: {}

	$scope.publicKey =
		key: null

	addNewForwardUrl = (repository) ->
		repository.newForwardUrl = repository.forwardUrl # needed when editing repository
		return repository

	getRepositories = () ->
		rpc 'repositories', 'read', 'getRepositories', null, (error, repositories) ->
			if error? then notification.error error
			else
				$scope.repositories = (addNewForwardUrl repository for repository in repositories)
				updateRepositoryForwardUrlUpdatedListeners()
				getMaxRepositoryCount()

	getMaxRepositoryCount = () ->
		rpc 'systemSettings', 'read', 'getMaxRepositoryCount', null, (error, maxRepositoryCount) ->
			if error? then notification.error error
			else
				$scope.maxRepositoryCount = maxRepositoryCount ? Number.POSITIVE_INFINITY
				updateRepositoryCountExceeded()

	updateRepositoryCountExceeded = () ->
		return if not $scope.maxRepositoryCount?
		$scope.exceededMaxRepositoryCount = $scope.repositories.length >= $scope.maxRepositoryCount
		showRepositoriesLimitWarningIfNecessary()

	showRepositoriesLimitWarningIfNecessary = () ->
		upgradeUrl = 'https://koalitycode.com/account/plan'
		if $routeParams.view is 'repositories' and $scope.repositories.length >= $scope.maxRepositoryCount
			notification.warning "Max number of repositories reached. <a href='#{upgradeUrl}'>Upgrade to increase this limit</a>"

	getPublicKey = () ->
		rpc 'repositories', 'read', 'getPublicKey', null, (error, publicKey) ->
			if error? then notification.error error
			else $scope.publicKey.key = publicKey

	getIsConnectedToGitHub = () ->
		rpc 'users', 'read', 'isConnectedToGitHub', null, (error, connectedToGitHub) ->
			if error? then notification.error error
			else $scope.isConnectedToGitHub = connectedToGitHub

	handleAddedRepositoryUpdate = (data) ->
		$scope.repositories.push addNewForwardUrl data
		updateRepositoryCountExceeded()

	handleRemovedRepositoryUpdate = (data) ->
		repositoryToRemoveIndex = (index for repository, index in $scope.repositories when repository.id is data.id)[0]
		$scope.repositories.splice repositoryToRemoveIndex, 1 if repositoryToRemoveIndex?
		updateRepositoryCountExceeded()

	createRepositoryForwardUrlUpdateHandler = (repository) ->
		return (data) ->
			repository.forwardUrl = data.forwardUrl
			repository.newForwardUrl = data.forwardUrl

	repositoryForwardUrlUpdatedListeners = []
	updateRepositoryForwardUrlUpdatedListeners = () ->
		repositoryForwardUrlUpdatedListener.unsubscribe() for repositoryForwardUrlUpdatedListener in repositoryForwardUrlUpdatedListeners
		repositoryForwardUrlUpdatedListeners = []

		for repository in $scope.repositories
			repositoryForwardUrlUpdatedListener = events('repositories', 'forward url updated', repository.id).setCallback(createRepositoryForwardUrlUpdateHandler(repository)).subscribe()
			repositoryForwardUrlUpdatedListeners.push repositoryForwardUrlUpdatedListener
	$scope.$on '$destroy', () -> repositoryForwardUrlUpdatedListener.unsubscribe() for repositoryForwardUrlUpdatedListener in repositoryForwardUrlUpdatedListeners

	addRepositoryEvents = events('users', 'repository added', initialState.user.id).setCallback(handleAddedRepositoryUpdate).subscribe()
	removeRepositoryEvents = events('users', 'repository removed', initialState.user.id).setCallback(handleRemovedRepositoryUpdate).subscribe()
	$scope.$on '$destroy', addRepositoryEvents.unsubscribe
	$scope.$on '$destroy', removeRepositoryEvents.unsubscribe

	getRepositories()
	getPublicKey()
	getIsConnectedToGitHub()

	$scope.toggleDrawer = (drawerName) ->
		if $scope.currentlyOpenDrawer is drawerName
			$scope.currentlyOpenDrawer = null
		else
			$scope.currentlyOpenDrawer = drawerName
			$scope.currentlyEditingRepositoryId = null

	$scope.editRepository = (repository) ->
		otherRepository.deleting = false for otherRepository in $scope.repositories
		$scope.currentlyEditingRepositoryId = repository?.id

	$scope.saveRepository = (repository) ->
		requestParams =
			id: repository.id
			forwardUrl: repository.newForwardUrl
		rpc 'repositories', 'update', 'setForwardUrl', requestParams, (error) ->
			$scope.currentlyEditingRepositoryId = null

			if error? then notification.error error
			else
				repository.forwardUrl = repository.newForwardUrl
				notification.success "Forward url changed for: #{repository.name}"

	$scope.deleteRepository = (repository) ->
		if not repository.password? or repository.password is ''
			notification.error 'You must provide a password to delete repository: ' + repository.name
			return

		return if repository.makingDeleteRequest
		repository.makingDeleteRequest = true

		requestParams =
			id: repository.id
			password: repository.password
		rpc 'repositories', 'delete', 'deleteRepository', requestParams, (error) ->
			repository.makingDeleteRequest = false
			if error? then notification.error error
			else notification.success 'Successfully deleted repository: ' + repository.name

	$scope.createManualRepository = () ->
		return if $scope.addRepository.manual.makingRequest
		$scope.addRepository.manual.makingRequest = true

		rpc 'repositories', 'create', 'createRepository', $scope.addRepository.manual, false, (error, repositoryId) ->
			$scope.addRepository.manual.makingRequest = false
			if error? then notification.error error
			else
				notification.success 'Created repository ' + $scope.addRepository.manual.name
				$scope.clearAddRepository()

	$scope.clearAddRepository = () ->
		$scope.addRepository.setupType = 'manual'
		$scope.addRepository.manual = {}
		$scope.addRepository.gitHub = {}
		$scope.currentlyOpenDrawer = null
]
