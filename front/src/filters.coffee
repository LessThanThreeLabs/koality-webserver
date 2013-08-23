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

			githubMatch = /^git@github.com:(.*?)(.git)?$/.exec forwardUrl
			if githubMatch? and githubMatch[1]?
				return '<a href="https://github.com/' + githubMatch[1] + '/commit/' + sha + '">View in GitHub</a>'

			bitbucketMatch = /^git@bitbucket.[org|com]:(.*?)(.git)?$/.exec forwardUrl
			if bitbucketMatch? and bitbucketMatch[1]?
				return '<a href="https://bitbucket.org/' + bitbucketMatch[1] + '/commits/' + sha + '">View in BitBucket</a>'

			return null
	])
