window.AdminUsers = ['$scope', 'initialState', 'rpc', 'events', 'notification', ($scope, initialState, rpc, events, notification) ->
	$scope.orderByPredicate = 'privilege'
	$scope.orderByReverse = false

	$scope.addUsers =
		makingRequest: false
		drawerOpen: false

	getUsers = () ->
		addPrivilegesToUser = (user) ->
			user.privilege = if user.isAdmin then 'Admin' else 'User'
			return user

		rpc 'users', 'read', 'getAllUsers', null, (error, users) ->
			$scope.users = (addPrivilegesToUser user for user in users)

	handleUserAdded = (data) ->
		$scope.users.push addPrivilegesToUser data

	handleUserRemoved = (data) ->
		userToRemoveIndex = (index for user, index in $scope.users when user.id is data.id)[0]
		$scope.users.splice userToRemoveIndex, 1 if userToRemoveIndex?

	addUserEvents = events('users', 'user created', initialState.user.id).setCallback(handleUserAdded).subscribe()
	removeUserEvents = events('users', 'user removed', initialState.user.id).setCallback(handleUserRemoved).subscribe()
	$scope.$on '$destroy', addUserEvents.unsubscribe
	$scope.$on '$destroy', removeUserEvents.unsubscribe

	getUsers()

	$scope.removeUser = (user) ->
		rpc 'users', 'delete', 'deleteUser', id: user.id, (error) ->
			if error? then notification.error 'Unable to delete user ' + user.email

	$scope.submitUsers = () ->
		return if $scope.addUsers.makingRequest
		$scope.addUsers.makingRequest = true

		rpc 'users', 'create', 'inviteUsers', emails: $scope.addUsers.emails, (error) ->
			$scope.addUsers.makingRequest = false
			if error? then notification.error error
			else 
				notification.success 'Invited new users'
				$scope.clearAddUsers()

	$scope.clearAddUsers = () ->
		$scope.addUsers.emails = ''
		$scope.addUsers.drawerOpen = false
]
