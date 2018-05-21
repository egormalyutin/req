require = do ->

	#####################	
	##### VARIABLES #####
	#####################	

	global = window
	cache = {}
	result = {}

	#####################
	##### POLYFILLS #####
	#####################

	# string polyfills
	if String.prototype.startsWith
		startsWith = (a, b, pos) ->
			a.startsWith b, pos
	else
		startsWith = (a, b, pos) ->
			return a.substr((not pos) or (if pos < 0 then 0 else +pos), b.length) is b

	if String.prototype.endsWith
		endsWith = (a, b, pos) ->
			a.endsWith b, pos
	else
		endsWith = (a, b, pos) ->
			if pos is undefined or pos > a.length
				pos = a.length
			return a.substring(pos - b.length, pos) is search

	# currentScript polyfill
	if document.currentScript
		getCurrentScript = -> document.currentScript
	else
		getCurrentScript = ->
			scripts = document.getElementsByTagName "script"
			return scripts[scripts.length - 1]

	#################
	##### PATHS #####
	#################

	# example:
	# resolve("a", "./b", "./c/d", "../e") => "a/b/c/e"
	resolve = (paths...) ->
		chain = []
		firstSep = ""
		first = true
		for path in paths
			path = path.trim()
			continue if path == ""
			if first
				if startsWith path, "/"
					firstSep = "/"
				else if startsWith path, "./"
					firstSep = "./"

				first = false
			splitted = path.split "/"
			for chunk in splitted when chunk not in [".", ""]
				if chunk is ".."
					chain.pop()
				else
					chain.push chunk

		return firstSep + chain.join "/"

	getDirname = (path) ->
		return path.replace(/\\/g,'/').replace(/\/[^\/]*$/, '');

	###############
	##### NET #####
	###############

	firstRequest = true

	# do sync request
	request = (url) ->
		xhr = new XMLHttpRequest
		xhr.open "GET", url, false
		xhr.overrideMimeType "text/plain"
		xhr.send null

		# message
		if firstRequest and result.require.message
			console.log "Sorry, but req.js needs sync requests. If you don't want to use sync requests, you can try Require.JS. You can turn off this message by 'require.message = false'."
			firstRequest = false

		# check status
		if xhr.status isnt 200
			throw new Error "Failed to load URL #{url}"
		else
			return xhr.responseText

	################
	##### MAIN #####
	################

	mainSymbol = {}

	# create new require() function
	makeRequire = (root) ->
		rq = (localPath) ->
			# type check
			if typeof localPath isnt "string"
				throw new TypeError "Path must be string, got #{typeof localPath}"

			# if this require is require from file, not from module
			if root is mainSymbol
				path = resolve getDirname(getCurrentScript().src), localPath
			else
				path = resolve root, localPath

			# paths
			path += ".js" unless endsWith path, ".js"
			dirname = getDirname path

			# find cache
			return cache[path].exports if cache[path]
				
			# init module
			module = { 
				id: path
				filename: path
				loaded: false
				exports: {}
			}

			# download code
			code = request path

			# execute code of module
			(new Function "global, module, exports, require, __dirname, __filename", code).call(global, global, module, module.exports, makeRequire(dirname), dirname, path)

			# cache module
			cache[module.id] = module
			return module.exports

		rq.cache = cache
		rq.message = true
		return rq

	result.require = makeRequire mainSymbol
	return result.require
