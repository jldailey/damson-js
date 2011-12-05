require('./lib')

type2func = {}

register = (type, func) ->
	type2func[type] = func

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

register "region", (node) ->
	@regions ?= {}
	action = @render Object.Get(node, "ACTION", "new")
	name = @render Object.Get(node, "NAME")
	if not name?
		return "type=region requires a name"
	content = @render Object.Get(node, "CONTENT")
	switch action
		when "new"
			r = {
				name: name
			}
			(@regions[name] ?= {
				buffer: ""
				outputs: []
			}).outputs.push r
			return r
		when "append"
		when "replace"
		when "prepend"
	return null

register "test_require", {
	pre: () ->
	post: () ->
}

Renderer = (application, request = {}) ->
	if Object.IsWindow @
		return new Renderer(application, request)
	@application = application
	@request = request
	@stack = []
	@processors = []
	@render = (node) ->
		@stack.push(node)
		if "requires" of node
			if not Object.IsArray(node.requires)
				node.requires = [ node.requires ]
				for r in node.requires
					if @processors.indexOf(r) is -1
						@processors.splice 0,0,r
						lookup(type).pre.call(@, node)

		try
			return switch true
				when Object.IsArray node then Array.Compact [@render(x) for x in node]
				when Object.IsSimple node then node.toString()
				when Object.IsObject(node) and 'type' of node and node.type of type2func
					@render lookup(type).call(@, node)
				else node # use every part of the buffalo
		finally
			@stack.pop()
	return @

if exports?
	exports.register = register
	exports.lookup = lookup
	exports.Renderer = Renderer

