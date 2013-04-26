crypto = require 'crypto'


module.exports = (grunt) ->

	grunt.initConfig
		package: grunt.file.readJSON('package.json');
		sourceDirectory: 'src'
		testDirectory: 'test'
		compiledDirectory: 'libs'
		uglifiedDirectory: 'uglified'
		tarredPackageName: '<%= package.name %>-<%= package.version %>.tgz'
		s3Prefix: 'cd855575be99a357'
		s3TarredPackageLocation: 's3://koality_code/libraries/<%= s3Prefix %>-<%= tarredPackageName %>'

		shell:
			options:
				stdout: true
				stderr: true
				failOnError: true

			compile:
				command: 'iced --compile --lint --output <%= compiledDirectory %>/ <%= sourceDirectory %>/'

			runServer:
				command: [
					'mkdir -p logs/redis',
					'(redis-server redis/conf/sessionStoreRedis.conf &)',
					'(redis-server redis/conf/createAccountRedis.conf &)',
					'(redis-server redis/conf/createRepositoryRedis.conf &)',
					'node --harmony <%= compiledDirectory %>/index.js --httpsPort 10443',
				].join ' && '

			removeCompile:
				command: 'rm -rf <%= compiledDirectory %>'

			removeUglify:
				command: 'rm -rf <%= uglifiedDirectory %>'

			replaceCompiledWithUglified:
				command: [
					'rm -rf <%= compiledDirectory %>'
					'mv <%= uglifiedDirectory %> <%= compiledDirectory %>'
					].join ' && '

			pack:
				command: 'npm pack'

			publish:
				command: 's3cmd put --acl-public --guess-mime-type <%= tarredPackageName %> <%= s3TarredPackageLocation %>'

			test:
				command: 'karma start front/test/karma.unit.conf.js --browsers PhantomJS --single-run'

		uglify:
			options:
				preserveComments: 'some'

			libs:
				files: [
					expand: true
					cwd: '<%= compiledDirectory %>/'
					src: ['**/*.js']
					dest: '<%= uglifiedDirectory %>/'
					ext: '.js'
				]

		watch:
			compile:
				files: '<%= sourceDirectory %>/**/*.coffee'
				tasks: 'compile'

			test:
				files: ['<%= sourceDirectory %>/**/*.coffee', '<%= testDirectory %>/**/*.spec.coffee']
				tasks: 'test'

	grunt.loadNpmTasks 'grunt-contrib-uglify'
	grunt.loadNpmTasks 'grunt-contrib-watch'
	grunt.loadNpmTasks 'grunt-shell'

	grunt.registerTask 'default', ['compile']
	grunt.registerTask 'compile', ['shell:removeCompile', 'shell:compile']
	grunt.registerTask 'run', ['compile', 'shell:runServer']
	grunt.registerTask 'test', ['compile', 'shell:test']
	grunt.registerTask 'make-ugly', ['shell:removeUglify', 'uglify']
	grunt.registerTask 'production', ['compile', 'make-ugly', 'shell:replaceCompiledWithUglified']
	grunt.registerTask 'publish', ['production', 'shell:pack', 'shell:publish']
