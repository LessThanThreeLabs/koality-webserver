'use strict'

angular.module('koality.filter', ['koality.service']).
	filter('fileSuffix', ['fileSuffixAdder', (fileSuffixAdder) ->
		(input) ->
			return fileSuffixAdder.addFileSuffix input
	]).
	filter('emailToAlias', [() ->
		(input) ->
			if input.indexOf '@' isnt -1
				return input.substring 0, input.indexOf '@'
			else
				return input
	]).
	filter('ascii', [() ->
		(input) ->
			return null if not input? or typeof input isnt 'string'

			input = input.replace /\n/g, '<br>'
			input = input.replace /\t/g, '    '
			input = input.replace /\040/g, '&nbsp;'
			return input
	]).
	filter('onlyFirstLine', [() ->
		(input) ->
			return null if not input? or typeof input isnt 'string'
			return input.split('\n')[0]
	]).
	filter('ansi', ['ansiParser', (ansiParser) ->
		(input) ->
			return null if not input? or typeof input isnt 'string'
			return ansiParsedLine = ansiParser.parse input
	]).
	filter('shaLink', [() ->
		(sha, forwardUrl) ->
			return null if not sha? or typeof sha isnt 'string'
			return null if not forwardUrl? or typeof forwardUrl isnt 'string'

			gitHubMatch = /^git@github.com:(.*?)(.git)?$/.exec forwardUrl
			if gitHubMatch? and gitHubMatch[1]?
				return "<a href='https://github.com/#{gitHubMatch[1]}/commit/#{sha}' target='_blank'>View Diff in GitHub</a>"

			bitBucketMatch = /^git@bitbucket.[org|com]:(.*?)(.git)?$/.exec forwardUrl
			if bitBucketMatch? and bitBucketMatch[1]?
				return "<a href='https://bitbucket.org/#{bitBucketMatch[1]}/commits/#{sha}' target='_blank'>View Diff in BitBucket</a>"

			return null
	])
