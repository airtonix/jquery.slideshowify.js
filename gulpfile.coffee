#!/bin/env coffee
browserify = require 'browserify'
coffeeify = require 'coffeeify'
buffer = require 'vinyl-buffer'
source = require 'vinyl-source-stream'
gulp = require 'gulp'
gutil = require 'gulp-util'
path = require 'path'
$ = do require 'gulp-load-plugins'
_ = require 'lodash'

paths =
	src: path.join __dirname, 'src', 'client'
	build: path.join __dirname, 'build'

paths = _.extend {}, paths,
	parts:
		html: "#{paths.src}/**/*.html"
		partials: "#{paths.src}/**/*.tpl.{html,jade,md,markdown}"
		coffee: "#{paths.src}/js/**/*.coffee"
		js: "#{paths.src}/**/*.js"
		vendorStyles: "#{paths.src}/css/vendor/*.css"
		appStyles: "#{paths.src}/css/{screen,print}.scss"
		svg: "#{paths.src}/img/*.svg"
		img: "#{paths.src}/img/**/*.{png,jpg,jpeg,gif}"
		fonts: "#{paths.src}/fonts/*"

handlers =
	error: (err) ->
		gutil.beep()
		console.log "PlumberError:", err

#
# Job: Scripts Angular Partials
gulp.task 'scripts-partials', ->
	gulp.src "#{paths.parts.partials}"
	.pipe $.plumber()
	.pipe $.if /[.]jade$/, $.jade()
	.pipe $.if /[.]md|markdown$/, $.marked()
	.pipe $.angularHtmlify()
	.pipe $.angularTemplatecache
		root: "/"
		standalone: true
		module: "app.templates"
	.pipe gulp.dest "#{paths.build}/js"

#
# Job: Scripts Vendor
gulp.task 'scripts-vendor', ->
	entryPath = "#{paths.src}/js/vendor.coffee"
	browserify
		entries: [ entryPath ]
		extensions: ['.coffee']
		insertGlobals: true
	.bundle debug: true
	.pipe source 'vendor.js'
	.pipe gulp.dest "#{paths.build}/js"

#
# Job: Scripts Vendor
gulp.task 'scripts-mock', ->
	entryPath = "#{paths.src}/js/mock/index.coffee"
	browserify
		entries: [ entryPath ]
		extensions: ['.coffee']
		insertGlobals: true
	.bundle debug: true
	.pipe source 'mocks.js'
	.pipe gulp.dest "#{paths.build}/js"

#
# Job: Scripts Application
gulp.task 'scripts-app', ->
	entryPath = "#{paths.src}/js/index.coffee"
	browserify
		entries: [ entryPath ]
		extensions: ['.coffee']
		insertGlobals: true
	.bundle debug: true
	.pipe source 'app.js'
	.pipe gulp.dest "#{paths.build}/js"

#
# Task: Scripts
gulp.task 'scripts-production', ['scripts-vendor', 'scripts-partials', 'scripts-app']
gulp.task 'scripts-development', ['scripts-vendor', 'scripts-partials', 'scripts-mock', 'scripts-app']

#
# Task: Styles
gulp.task 'styles-app', ->
	gulp.src "#{paths.parts.appStyles}"
	.pipe $.plumber handlers.error
	.pipe $.sass
		# sourceComments: 'map'
		includePath: [
			"./node_modules/bootstrap-sass/assets/stylesheets/"
			"./node_modules/node-bourbon/assets/stylesheets/"
		]
	.pipe $.autoprefixer "last 1 version"
	.pipe $.cssmin keepSpecialComments: 0
	.pipe gulp.dest "#{paths.build}/css"
	.pipe $.size()

gulp.task 'styles-vendor', ->
	gulp.src "#{paths.parts.vendorStyles}"
	.pipe $.plumber handlers.error
	.pipe $.concat "vendor.css"
	.pipe $.autoprefixer "last 1 version"
	.pipe $.cssmin keepSpecialComments: 0
	.pipe gulp.dest "#{paths.build}/css"
	.pipe $.size()

gulp.task 'styles', ['styles-vendor', 'styles-app']


#
# Task: Html > Revv'd
gulp.task 'html', ->
	gulp.src "#{paths.parts.html}"
	.pipe $.plumber handlers.error

	# .pipe $.useref.assets()
	# .pipe $.useref.restore()
	.pipe $.useref()
	.pipe $.size()
	.pipe gulp.dest paths.build

#
# Task: Minify SVG
gulp.task 'svg', ->
	gulp.src "#{paths.parts.svg}"
		.pipe $.plumber()
		.pipe $.svgmin()
		.pipe gulp.dest "#{paths.build}/img"

#
# Task: Copy Fonts
gulp.task 'fonts', ->
	gulp.src "#{paths.parts.fonts}"
	.pipe $.plumber()
	.pipe gulp.dest "#{paths.build}/fonts"

#
# Task: Copy Images
gulp.task 'images', ->
	gulp.src "#{paths.parts.images}"
	.pipe $.plumber()
	.pipe gulp.dest "#{paths.build}/img"

#
# Task: Clean
gulp.task 'clean', ->
	gulp.src ["#{paths.build}"], read: false
		.pipe $.clean()

#
# Task: Connect
gulp.task 'server', ->
	gulp.src "#{paths.build}"
	.pipe $.plumber()
	.pipe $.webserver
		host: '0.0.0.0'
		port: 8080
		root: paths.build
		fallback: 'index.html'
		livereload: true
	.on 'error', ->
		console.log "Webserver.error: 	", arguments

#
# Task: Build
gulp.task 'build', ['html', 'styles', 'scripts-production', 'fonts', 'images']

#
# Custom: Default task
gulp.task 'default', ['html', 'styles', 'scripts-development', 'fonts', 'images', 'server'], ->

	# Watch: app files
	gulp.watch [
		"#{paths.parts.html}"
	], ['html']

	gulp.watch [
		"#{paths.src}/js/vendor.coffee"
	], ['scripts-vendor']

	gulp.watch [
		"#{paths.parts.partials}"
	], ['scripts-partials']

	gulp.watch [
		"#{paths.parts.coffee}"
	], ['scripts-app']

	gulp.watch [
		"#{paths.src}/js/mock/*.coffee"
	], ['scripts-mock']
	# Watch .scss files
	gulp.watch [
		"#{paths.parts.vendorStyles}"
		"#{paths.parts.appStyles}"
		"#{paths.src}/css/**/*.scss"
	], ['styles']

	# # Watch stuff to copy files
	gulp.watch [
		"#{paths.parts.img}"
		"#{paths.parts.fonts}"
	], ['images', 'fonts']
