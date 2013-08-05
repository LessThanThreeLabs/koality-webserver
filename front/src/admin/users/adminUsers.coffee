'use strict'

window.AdminUsers = ['$scope', 'initialState', 'rpc', 'events', 'notification', ($scope, initialState, rpc, events, notification) ->
	$scope.orderByPredicate = 'privilege'
	$scope.orderByReverse = false

	$scope.userId = initialState.user?.id
	$scope.currentlyEditingUserId = null
	$scope.currentlyOpenDrawer = null

	$scope.addUsers =
		makingRequest: false

	addUserPrivilege = (user) ->
		user.privilege = if user.isAdmin then 'Admin' else 'User'
		user.newPrivilege = user.privilege  # used while in edit mode
		return user

	getUsers = () ->
		rpc 'users', 'read', 'getAllUsers', null, (error, users) ->
			$scope.users = (addUserPrivilege user for user in users)

	handleUserAdded = (data) ->
		$scope.users.push addUserPrivilege data

	handleUserRemoved = (data) ->
		userToRemoveIndex = (index for user, index in $scope.users when user.id is data.id)[0]
		$scope.users.splice userToRemoveIndex, 1 if userToRemoveIndex?

	handleUserAdminStatusChanged = (data) ->
		userToUpdate = (user for user in $scope.users when user.id is data.id)[0]
		privilege = if data.isAdmin then 'Admin' else 'User'
		userToUpdate.privilege = privilege if userToUpdate?
		userToUpdate.newPrivilege = privilege if userToUpdate?

	addUserEvents = events('users', 'user created', initialState.user.id).setCallback(handleUserAdded).subscribe()
	removeUserEvents = events('users', 'user removed', initialState.user.id).setCallback(handleUserRemoved).subscribe()
	adminStatusEvents = events('users', 'user admin status', initialState.user.id).setCallback(handleUserAdminStatusChanged).subscribe()
	$scope.$on '$destroy', addUserEvents.unsubscribe
	$scope.$on '$destroy', removeUserEvents.unsubscribe
	$scope.$on '$destroy', adminStatusEvents.unsubscribe

	getUsers()

	$scope.toggleDrawer = (drawerName) ->
		if $scope.currentlyOpenDrawer is drawerName
			$scope.currentlyOpenDrawer = null
		else
			$scope.currentlyOpenDrawer = drawerName

	$scope.editUser = (user) ->
		$scope.currentlyEditingUserId = user?.id

	$scope.saveUser = (user) ->
		requestParams =
			id: user.id
			isAdmin: user.newPrivilege is 'Admin'
		rpc 'users', 'update', 'changeAdminStatus', requestParams, (error) ->
			$scope.currentlyEditingUserId = null
			if error? then notification.error error
			else 
				user.privilege = user.newPrivilege
				notification.success "Adimn status changed for: #{user.firstName} #{user.lastName}"

	$scope.deleteUser = (user) ->
		rpc 'users', 'delete', 'deleteUser', id: user.id, (error) ->
			$scope.currentlyEditingUserId = null
			if error? then notification.error error
			else notification.success "Deleted user #{user.firstName} #{user.lastName}"

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
		$scope.currentlyOpenDrawer = null
]
