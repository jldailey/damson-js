require('./lib')

registry = {}

register = (type, func) ->
	if not (type of registry)
		registry[type] = []
	registry[type].push(func)
render = (node) ->
	if Object.IsArray node
		return Array.Compact [render(x) for x in node]
	if Object.IsSimple node
		return node.toString()
	if Object.IsObject node
		if 'type' of node and node.type of registry
			return render [f(node) for f in registry[node.type]]

if exports?
	exports.DAMSON = {
		register: register
		render: render
	}

