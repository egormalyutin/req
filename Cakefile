option "-w", "--watch",  "watch file"
option "-m", "--minify", "minify file"

watching = false

task "build", (options) ->
	{ compile } = require "coffeescript"
	fs = require "fs"

	code = fs.readFileSync "src/main.coffee"
	run = ->
	code = compile code.toString(), bare: true
	try fs.mkdirSync "build"

	fs.writeFileSync "build/req.js", code

	if options.minify
		{ minify } = require "uglify-es"
		{ code } = minify code
		fs.writeFileSync "build/req.min.js", code

	if options.watch and not watching
		{ Gaze }    = require "gaze"
		{ inspect } = require "util"
		gaze = new Gaze "src/main.coffee"

		gaze.on "all", (event) ->
			if event isnt "deleted"
				try 
					invoke "build"
				catch e
					console.log inspect e

		watching = true

	console.log "Builded"