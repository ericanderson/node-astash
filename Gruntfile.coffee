module.exports = (grunt) ->
  grunt.loadNpmTasks('grunt-contrib-coffee')
  grunt.loadNpmTasks('grunt-coffeelint')
  grunt.loadNpmTasks('grunt-contrib-watch')

  grunt.initConfig({
    watch:
      scripts:
        files: 'src/**/*.coffee'
        tasks: ['default']
        options:
          debounceDelay: 250
          atBegin: true
    coffee:
      compile:
        options:
          sourceMap: true
        files:
          "lib/astash.js": "src/astash.coffee"
    coffeelint:
      app: ['src/astash.coffee']
      options:
        no_trailing_whitespace:
          level: 'error'
        line_endings:
          value: 'unix'
          level: 'error'
        max_line_length:
          value: 120
        no_implicit_braces:
          level: 'error'
        no_unnecessary_fat_arrows:
          level: 'error'
  })

  grunt.registerTask 'default', ['coffeelint', 'coffee']
  grunt.registerTask 'test', ['coffeelint']
  grunt.registerTask 'prepublish', ['coffee']