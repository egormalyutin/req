require = do ->
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

	# resolve a sequence of paths
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

	# get dirname of path
	getDirname = (path) ->
		return path.replace(/\\/g,'/').replace(/\/[^\/]*$/, '');

	###############
	##### NET #####
	###############

	firstRequest = true

	# do sync request
	requestSync = (url) ->
		xhr = new XMLHttpRequest
		xhr.open "GET", url, false
		xhr.overrideMimeType "text/javascript"
		xhr.send null

		# message
		if firstRequest and result.require.message
			console.log "Sorry, but req.js needs sync requests for sync mode. If you don't want to use sync requests, you can use requre.async or Require.JS. You can turn off this message by 'require.message = false'."
			firstRequest = false

		# check status
		if xhr.status isnt 200
			throw new Error "Failed to load URL #{url}"
		else
			return xhr.responseText

	# do async request
	requestAsync = (url) ->
		return new Promise (r) ->
			xhr = new XMLHttpRequest
			xhr.onreadystatechange = ->
				if xhr.readyState is 4 and xhr.status is 200
					r xhr.responseText

			xhr.open "GET", url, true
			xhr.overrideMimeType "text/javascript"
			xhr.send null

	################
	##### MAIN #####
	################

	mainSymbol = {}

	# init new module
	initModule = (root, localPath) ->
		# type check
		if typeof localPath isnt "string"
			throw new TypeError "Path must be string, got #{typeof localPath}"

		# if this require is require from file, not from module
		if root is mainSymbol
			path = resolve getDirname(getCurrentScript().src or ""), localPath
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

		return [module, path, dirname]

	# create new require() function
	makeRequire = (root) ->
		rq = (localPath) ->
			[module, path, dirname] = initModule root, localPath

			code = requestSync path

			# execute code of module
			(new Function "global, module, exports, require, __dirname, __filename", code).call(global, global, module, module.exports, makeRequire(dirname), dirname, path)

			cache[module.id] = module
			module.loaded = true

			return module.exports

		rq.async = (localPath) ->
			[module, path, dirname, code] = initModule root, localPath

			# download code
			code = await requestAsync path

			# execute code of module
			await (new Function "global, module, exports, require, __dirname, __filename", 
				"return (async function() { " + code + " })"
			).call(global, global, module, module.exports, makeRequire(dirname), dirname, path)()

			cache[module.id] = module
			module.loaded = true

			return module.exports

		rq.cache = cache
		rq.message = true
		return rq

	result.require = makeRequire mainSymbol
	return result.require
