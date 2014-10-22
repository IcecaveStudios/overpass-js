module.exports = (grunt) ->
  grunt.initConfig
    coffee:
      compile:
        cwd: 'src'
        src: '**/*.coffee'
        dest: 'lib'
        ext: '.js'
        expand: true

    env:
      coverage:
        TEST_ROOT: __dirname + '/build/instrument/lib'

    instrument:
      files: 'lib/**/*.js'

    jasmine_node:
      options:
        coffee: true
      all: 'spec'

    makeReport:
      src: 'build/reports/coverage.json'

    coveralls:
      src: 'build/reports/lcov.info'

    open:
      coverage:
        path: 'build/reports/lcov-report/index.html'

  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-coveralls'
  grunt.loadNpmTasks 'grunt-env'
  grunt.loadNpmTasks 'grunt-istanbul'
  grunt.loadNpmTasks 'grunt-jasmine-node'
  grunt.loadNpmTasks 'grunt-open'

  grunt.registerTask 'build', 'coffee:compile'
  grunt.registerTask 'test', ['build', 'jasmine_node']
  grunt.registerTask 'pre-coverage', ['env:coverage', 'build', 'instrument']
  grunt.registerTask 'post-coverage', ['storeCoverage', 'makeReport']
  grunt.registerTask 'coverage', ['pre-coverage', 'test', 'post-coverage']
  grunt.registerTask 'open-coverage', ['coverage', 'open:coverage']
  grunt.registerTask 'travis', ['coverage', 'coveralls']

  grunt.registerTask 'default', 'test'
