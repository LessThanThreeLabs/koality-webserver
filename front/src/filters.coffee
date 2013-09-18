'use strict'

angular.module('koality.filter', ['koality.service']).
	filter('fileSuffix', ['fileSuffixAdder', (fileSuffixAdder) ->
		(input) ->
			return fileSuffixAdder.addFileSuffix input
	]).
	filter('emailToAlias', [() ->
		(input) ->
			return null if not input? or typeof input isnt 'string'

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
		(headSha, baseSha, forwardUrl) ->
			return null if not headSha? or typeof headSha isnt 'string'
			return null if not forwardUrl? or typeof forwardUrl isnt 'string'

			generateLink = (url, text) ->
				"<a href='#{url}' target='_blank'>#{text}</a>"

			gitHubMatch = /^git@github.com:(.+?)(\.git)?$/.exec forwardUrl
			if gitHubMatch? and gitHubMatch[1]?
				if baseSha? and typeof baseSha is 'string' and baseSha.length > 0
					return generateLink "https://github.com/#{gitHubMatch[1]}/compare/#{baseSha}...#{headSha}", 'View Diff in GitHub'
				else
					return generateLink "https://github.com/#{gitHubMatch[1]}/commit/#{headSha}", 'View Diff in GitHub'

			bitBucketGitMatch = /^git@bitbucket.(org|com):(.+?)(\.git)?$/.exec forwardUrl
			if bitBucketGitMatch? and bitBucketGitMatch[2]?
				return generateLink "https://bitbucket.org/#{bitBucketGitMatch[2]}/commits/#{headSha}", 'View Diff in BitBucket'

			bitBucketHgMatch = /^ssh:\/\/hg@bitbucket.(org|com)\/(.+?)(\.hg)?$/.exec forwardUrl
			if bitBucketHgMatch? and bitBucketHgMatch[2]?
				return generateLink "https://bitbucket.org/#{bitBucketHgMatch[2]}/commits/#{headSha}", 'View Diff in BitBucket'

			return null
	])
