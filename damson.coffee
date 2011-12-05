require('./lib')

type2func = {}

register = (type, func) ->
	type2func[type] = Function.Trace(func, "render #{type}")

lookup = (type) ->
	Object.Get(type2func, type, Function.Empty)

register "data", (node) ->
	key = @render Object.Get(node, "KEY", "")
	def = @render Object.Get(node, "DEF", "")
	for n in [@stack.length...0]
		val = Object.Get(@stack[i], key)
		if val?
			return @render val
	return def

register "region", (() ->
	return (node) ->
		name = @require 'region_processor'
		@regions ?= {}
		action = @render Object.Get(node, "ACTION", "new")
		content = @render Object.Get(node, "CONTENT")
		switch action
			when "new"
				return { TYPE: "region-placeholder", NAME: name }
			when "append"
				@regions[name].append content
			when "replace"
				@regions[name].replace content
			when "prepend"
				@regions[name].prepend content
			else
				return "type=region did not recognize action: '#{action}'"
		return null
)()

register "region_processor", {
	once: (node) ->
	every: (node) ->
		name = @render Object.Get(node, "NAME")
		@regions[name] ?= new String.Builder()
		return name
	post: (node) ->
		if Object.IsArray(node)
			for i in [0...node.length]
				n = node[i]
				if n.TYPE is "region-placeholder"
					node[i] = @regions[n.NAME].toString()
		else if node.TYPE is "region-placeholder"
			node = @regions[node.NAME].toString()
		return node
}

Renderer = (application, request = {}) ->
	if Object.IsWindow @
		return new Renderer(application, request)
	@application = application
	@request = request
	@stack = []
	@processors = []
	@require = Function.Trace(((name) =>
		obj = lookup(name)
		if @processors.indexOf(name) is -1
			@processors.splice 0,0,name
			obj?.once?.call(@, node)
		obj?.every?.call(@, node)
	), 'require')
	requireAll = (node) =>
		if "REQUIRES" of node
			if not Object.IsArray(node.REQUIRES)
				node.REQUIRES = [ node.REQUIRES ]
			for r in node.REQUIRES
				@require(r)
	finish = Function.Trace(((node) =>
		for p in @processors
			tmp = lookup(p)?.post?.call(@, node)
			if tmp?
				node = tmp
		return 'finished:'+Array.Compact node
	), 'finish')
	@render = Function.Trace(((node) =>
		if not node?
			return "not node"
		@stack.push(node)
		try
			ret = switch true
				when Object.IsArray node then "compacted:"+Array.Compact( @render(x) for x in node )
				when Object.IsSimple node then "stringed:"+node.toString()
				when Object.IsObject(node)
					requireAll(node)
					"rendered:"+@render lookup(node.TYPE).call(@, node)
				else node # use every part of the buffalo
			return ret
		finally
			@stack.pop()
			if @stack.length is 0
				return finish(ret)
	), 'render')
	return @

if exports?
	exports.register = register
	exports.lookup = lookup
	exports.Renderer = Renderer

console.log (new Renderer({})).render({ TYPE: "data", KEY: 'foo', DEF: 'bar' })
