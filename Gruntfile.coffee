module.exports = (grunt) ->
  grunt.initConfig
    pkg: grunt.file.readJSON 'package.json'
    jasmine_node:
      options:
        extensions: 'coffee'
        coffee: true
      all: ['spec']

  grunt.loadNpmTasks 'grunt-jasmine-node'

  grunt.registerTask 'test', ['jasmine_node']
  grunt.registerTask 'default', ['test']
  grunt.registerTask 'travis', ['test']
