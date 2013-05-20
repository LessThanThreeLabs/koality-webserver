assert = require 'assert'


exports.create = () ->
	return new DomainRetriever()


class DomainRetriever
	REFRESH_INTERVAL: 60000

	constructor: () ->
		@_modelConnection = null
		@_domain = null
		@_interval = null


	setModelConnection: (modelConnection) =>
		assert.ok modelConnection?
		@_modelConnection = modelConnection
		@beginRefreshingDomain()


	beginRefreshingDomain: () =>
		clearInterval @_interval if @_interval?

		@_refreshDomain()
		@_interval = setInterval (() => @_refreshDomain()), @REFRESH_INTERVAL


	_refreshDomain: () =>
		@_modelConnection.rpcConnection.systemSettings.read.get_website_domain_name 1, (error, domain) =>
			if error? then console.error error
			else @_domain = domain


	getDomain: (callback) =>
		if not @_domain? then callback 'domain unavailable'
		else callback null, @_domain
