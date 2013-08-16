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
	])
