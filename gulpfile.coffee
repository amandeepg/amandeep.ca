gulp = require 'gulp'
gulpLoadPlugins = require 'gulp-load-plugins'
browserSync = require 'browser-sync'
del = require 'del'
wiredep = require 'wiredep'

$ = gulpLoadPlugins()
reload = browserSync.reload

lint = (files, options) ->
  ->
    gulp.src files
    .pipe reload(
      stream: true
      once: true)
    .pipe $.eslint(options)
    .pipe $.eslint.format()
    .pipe $.if(!browserSync.active, $.eslint.failAfterError())

gulp.task 'styles', ->
  gulp.src 'app/styles/*.scss'
  .pipe $.sourcemaps.init()
  .pipe $.sass.sync(
    outputStyle: 'expanded'
    precision: 10
    includePaths: [ '.' ]).on('error', $.sass.logError)
  .pipe $.autoprefixer(browsers: [
    '> 1%'
    'last 2 versions'
    'Firefox ESR'
  ])
  .pipe $.sourcemaps.write()
  .pipe gulp.dest('.tmp/styles')
  .pipe reload(stream: true)

gulp.task 'scripts', ->
  gulp.src 'app/scripts/**/*.js'
  .pipe gulp.dest '.tmp/scripts'
  .pipe reload stream: true

gulp.task 'scripts-coffee', ->
  gulp.src 'app/scripts/**/*.coffee'
  .pipe $.sourcemaps.init()
  .pipe $.coffee()
  .pipe $.sourcemaps.write()
  .pipe gulp.dest '.tmp/scripts'
  .pipe gulp.dest '.tmp'

gulp.task 'scripts-yml', ->
  gulp.src 'app/scripts/**/*.yml'
  .pipe gulp.dest '.tmp/scripts'
  .pipe gulp.dest 'dist/scripts'
  .pipe reload stream: true

gulp.task 'lint', lint 'app/scripts/**/*.js'

gulp.task 'html', [
  'styles'
  'scripts'
  'scripts-coffee'
], ->
  gulp.src 'app/*.html'
  .pipe $.cdnizer(
    fallbackScript: ''
    fallbackTest: ''
    files: [
      {
        package: 'lodash'
        cdn: 'cdnjs:lodash.js'
      }
      {
        package: 'handlebars'
        cdn: 'cdnjs:handlebars.js'
      }
      {
        package: 'bootstrap'
        cdn: 'cdnjs:twitter-bootstrap'
      }
      {
        file: '**/material.js'
        package: 'bootstrap-material-design'
        cdn: 'cdnjs:bootstrap-material-design:js/${ filenameMin }'
      }
      {
        file: '**/ripples.js'
        package: 'bootstrap-material-design'
        cdn: 'cdnjs:bootstrap-material-design:js/${ filenameMin }'
      }
      {
        file: '**/bootstrap-material-design.css'
        package: 'bootstrap-material-design'
        cdn: 'cdnjs:bootstrap-material-design:css/${ filenameMin }'
      }
      {
        file: '**/ripples.css'
        package: 'bootstrap-material-design'
        cdn: 'cdnjs:bootstrap-material-design:css/${ filenameMin }'
      }
      {
        package: 'jquery'
        cdn: 'google:jquery'
      }
      'cdnjs:velocity:velocity.min.js'
      'cdnjs:velocity:velocity.ui.min.js'
      'cdnjs:modernizr'
      'cdnjs:js-yaml'
    ])
  .pipe $.useref(searchPath: [
    '.tmp'
    'app'
    '.'
  ])
  .pipe $.if '*.js', $.uglify()
  .pipe $.if '*.css', $.cssnano()
  .pipe $.if '*.html', $.htmlmin collapseWhitespace: true
  .pipe gulp.dest 'dist'

gulp.task 'images', ->
  gulp.src 'app/images/**/*'
  .pipe $.if($.if.isFile, $.cache($.imagemin(
    progressive: true
    interlaced: true
    svgoPlugins: [ { cleanupIDs: false } ]))
  .on('error', (err) ->
    console.log err
    @end()
    return
  ))
  .pipe gulp.dest 'dist/images'

gulp.task 'fonts', ->
  gulp.src(require('main-bower-files')('**/*.{eot,svg,ttf,woff,woff2}', (err) -> {}).concat('app/fonts/**/*'))
  .pipe gulp.dest '.tmp/fonts'
  .pipe gulp.dest 'dist/fonts'

gulp.task 'extras', ->
  gulp.src([
    'app/*.*'
    '!app/*.html'
  ], dot: true)
  .pipe gulp.dest 'dist'

gulp.task 'rev-replace', [ 'rev' ], ->
  gulp.src([
    'dist/index.html'
    'dist/scripts/*'
    'dist/styles/*'
  ], base: 'dist')
  .pipe($.revReplace(
    manifest: gulp.src '.tmp/rev-manifest.json'
    replaceInExtensions: [
      '.js'
      '.css'
      '.html'
      '.yml'
    ]))
  .pipe gulp.dest('dist')

gulp.task 'rev', [
  'styles'
  'scripts'
  'scripts-yml'
  'images'
  'fonts'
], ->
  gulp.src([
    'dist/styles/*'
    'dist/images/*'
    'dist/fonts/*'
    'dist/scripts/*'
  ], base: 'dist')
  .pipe $.clean force: true
  .pipe $.rev()
  .pipe gulp.dest 'dist'
  .pipe $.rev.manifest merge: true
  .pipe gulp.dest '.tmp/'

gulp.task 'clean', del.bind(null, [
  '.tmp'
  'dist'
])

gulp.task 'serve', [
  'styles'
  'scripts'
  'scripts-coffee'
  'fonts'
], ->
  browserSync
    notify: true
    port: 9000
    server:
      baseDir: [
        '.tmp'
        'app'
      ]
      routes: '/bower_components': 'bower_components'
  gulp.watch([
    'app/*.html'
    '.tmp/scripts/**/*.js'
    'app/images/**/*'
    'app/scripts/*.yml'
    '.tmp/fonts/**/*'
  ]).on 'change', reload
  gulp.watch 'app/styles/**/*.scss', [ 'styles' ]
  gulp.watch 'app/scripts/**/*.js', [ 'scripts' ]
  gulp.watch 'app/scripts/**/*.coffee', [ 'scripts-coffee' ]
  gulp.watch 'app/fonts/**/*', [ 'fonts' ]
  gulp.watch 'bower.json', [
    'wiredep'
    'fonts'
  ]
  return

gulp.task 'serve:dist', [ 'default' ], ->
  browserSync
    notify: false
    port: 9000
    server: baseDir: [ 'dist' ]
  return

# inject bower components
gulp.task 'wiredep', ->
  gulp.src('app/styles/*.scss').pipe(wiredep(ignorePath: /^(\.\.\/)+/)).pipe gulp.dest('app/styles')
  gulp.src('app/*.html').pipe(wiredep(
    exclude: [ 'bootstrap-sass' ]
    ignorePath: /^(\.\.\/)*\.\./)).pipe gulp.dest('app')
  return

gulp.task 'build', [
  'lint'
  'html'
  'scripts-yml'
  'images'
  'fonts'
  'extras'
  'rev-replace'
], ->
  gulp.src 'dist/**/*'
  .pipe $.size gzip: true, showFiles: true

gulp.task 'default', [ 'clean' ], ->
  gulp.start 'build'
  return
