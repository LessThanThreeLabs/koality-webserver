module.exports = (grunt) ->

	grunt.initConfig
		package: grunt.file.readJSON('package.json');
		backSourceDirectory: 'src'
		backCompiledDirectory: 'libs'
		backTestDirectory: 'test'
		backUglifiedDirectory: 'uglified'
		frontSourceDirectory: 'front/src'
		frontRootsDirectory: 'front/roots'
		frontHtmlDirectory: 'front/html'
		frontTestDirectory: 'front/test'
		frontCoffeeCompiledDirectory: 'front/js/src'
		frontLessCompiledDirectory: 'front/css/src'
		frontUglifiedDirectory: 'front/uglified'
		tarredPackageName: '<%= package.name %>-<%= package.version %>.tgz'
		s3Hash: 'cd855575be99a357'
		s3TarredPackageLocation: 's3://koality_code/libraries/private-<%= s3Hash %>/<%= tarredPackageName %>'

		shell:
			options:
				stdout: true
				stderr: true
				failOnError: true

			compileCoffee:
				command: [
					'iced --compile --output <%= backCompiledDirectory %>/ <%= backSourceDirectory %>/',
					'iced --compile --runtime window --output <%= frontCoffeeCompiledDirectory %>/ <%= frontSourceDirectory %>/'
				].join ' && '

			copyHtml:
				command: [
					'cd <%= frontSourceDirectory %>',
					'find . -name "*.html" | cpio -pdm ../html'
				].join ' && '

			runServer:
				command: [
					'(redis-server redis/conf/sessionStoreRedis.conf &)',
					'(redis-server redis/conf/createAccountRedis.conf &)',
					'node --harmony <%= backCompiledDirectory %>/index.js --httpPort 1080 --mode development',
				].join ' && '

			runServerProduction:
				command: [
					'(redis-server redis/conf/sessionStoreRedis.conf &)',
					'(redis-server redis/conf/createAccountRedis.conf &)',
					'node --harmony <%= backCompiledDirectory %>/index.js --httpPort 1080 --mode production',
				].join ' && '

			killServer:
				command: "pgrep -f '^node --harmony libs/index.js' | xargs kill"

			removeCompile:
				command: [
					'rm -rf <%= backCompiledDirectory %>',
					'rm -rf <%= frontCoffeeCompiledDirectory %>',
					'rm -rf <%= frontLessCompiledDirectory %>',
					'rm -rf <%= frontHtmlDirectory %>'
				].join ' && '

			removeUglify:
				command: [
					'rm -rf <%= backUglifiedDirectory %>',
					'rm -rf <%= frontUglifiedDirectory %>'
				].join ' && '

			replaceCompiledWithUglified:
				command: [
					'rm -rf <%= backCompiledDirectory %>',
					'mv <%= backUglifiedDirectory %> <%= backCompiledDirectory %>',
					'rm -rf <%= frontCoffeeCompiledDirectory %>',
					'mv <%= frontUglifiedDirectory %> <%= frontCoffeeCompiledDirectory %>'
					].join ' && '

			pack:
				command: 'npm pack'

			publish:
				command: 's3cmd put --acl-public --guess-mime-type <%= tarredPackageName %> <%= s3TarredPackageLocation %>'

			testFront:
				command: 'karma start <%= frontTestDirectory %>/karma.unit.conf.js --browsers PhantomJS --single-run'

			testBack: 
				command: 'jasmine-node --color --coffee --forceexit <%= backTestDirectory %>/'

		uglify:
			options:
				preserveComments: 'some'

			back:
				files: [
					expand: true
					cwd: '<%= backCompiledDirectory %>/'
					src: ['**/*.js']
					dest: '<%= backUglifiedDirectory %>/'
					ext: '.js'
				]

			front:
				files: [
					expand: true
					cwd: '<%= frontCoffeeCompiledDirectory %>/'
					src: ['**/*.js']
					dest: '<%= frontUglifiedDirectory %>/'
					ext: '.js'
				]

		less:
			development:
				files: [
					expand: true
					cwd: '<%= frontSourceDirectory %>/'
					src: ['**/*.less']
					dest: '<%= frontLessCompiledDirectory %>/'
					ext: '.css'
				]

			production:
				options:
					yuicompress: true
				files: [
					expand: true
					cwd: '<%= frontSourceDirectory %>/'
					src: ['**/*.less']
					dest: '<%= frontLessCompiledDirectory %>/'
					ext: '.css'
				]

		watch:
			compile:
				files: ['<%= backSourceDirectory %>/**/*.coffee', '<%= frontSourceDirectory %>/**/*.coffee', '<%= frontSourceDirectory %>/**/*.less']
				tasks: ['compile']

			test:
				files: ['<%= backSourceDirectory %>/**/*.coffee', '<%= frontSourceDirectory %>/**/*.coffee', '<%= frontSourceDirectory %>/**/*.less', '<%= frontTestDirectory %>/**/*.coffee']
				tasks: ['compile', 'test']

			run:
				files: ['<%= backSourceDirectory %>/**/*.coffee', '<%= frontSourceDirectory %>/**/*.coffee', '<%= frontSourceDirectory %>/**/*.less', '<%= frontSourceDirectory %>/**/*.html', '<%= frontRootsDirectory %>/**/*.ejs', '<%= frontRootsDirectory %>/**/*.json']
				tasks: ['shell:killServer', 'compile', 'run']
				options:
					interrupt: true

	grunt.loadNpmTasks 'grunt-contrib-uglify'
	grunt.loadNpmTasks 'grunt-contrib-less'
	grunt.loadNpmTasks 'grunt-contrib-watch'
	grunt.loadNpmTasks 'grunt-shell'

	grunt.registerTask 'default', ['compile']
	grunt.registerTask 'compile', ['shell:removeCompile', 'shell:compileCoffee', 'less:development', 'shell:copyHtml']
	grunt.registerTask 'compile-production', ['shell:removeCompile', 'shell:compileCoffee', 'less:production']

	grunt.registerTask 'run', ['shell:runServer']
	grunt.registerTask 'run-production', ['shell:runServerProduction']

	grunt.registerTask 'test', ['shell:testFront', 'shell:testBack']
	grunt.registerTask 'test-front', ['shell:testFront']
	grunt.registerTask 'test-back', ['shell:testBack']

	grunt.registerTask 'make-ugly', ['shell:removeUglify', 'uglify']
	grunt.registerTask 'production', ['compile-production', 'make-ugly', 'shell:replaceCompiledWithUglified']
	grunt.registerTask 'publish', ['production', 'shell:pack', 'shell:publish']
