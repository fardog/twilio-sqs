module.exports = (grunt) ->
  grunt.initConfig data=
    pkg: grunt.file.readJSON 'package.json'
    coffeelint:
      precommit:
        files:
          src: ['src/*.coffee']
    coffee:
      precommit:
        expand: true,
        flatten: true,
        cwd: 'src',
        src: ['*.coffee'],
        dest: 'lib',
        ext: '.js'
  
  grunt.loadNpmTasks 'grunt-contrib-coffee'
  grunt.loadNpmTasks 'grunt-coffeelint'
  grunt.registerTask 'default', ['coffee']
  grunt.registerTask 'precommit', ['coffeelint:precommit', 'coffee:precommit']

