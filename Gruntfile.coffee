module.exports = (grunt) ->
  'use strict'
  pkg = require './package.json'
  grunt.initConfig
    clean:
      all: [ "lib" ]
    coffee:
      options:
        bare: true
      src:
        files:
          'lib/BabyFtpd.js':  'src/BabyFtpd.coffee'
  
  for name of pkg.devDependencies when name.substring(0, 6) is 'grunt-' and name isnt "grunt-cli"
    grunt.loadNpmTasks name
  
  grunt.registerTask 'default', [
    'clean'
    'coffee'
  ]
