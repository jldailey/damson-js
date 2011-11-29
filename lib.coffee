
OBJECT_RE = /\[object (\w+)\]/

Object.Keys = (o, inherited = false) -> # Object.Keys(/o/, [/inherited/]) - get a list of key names
	# by default, does not include properties inherited from a prototype
	keys = []; j = 0
	for i of o
		if inherited or o.hasOwnProperty(i)
			keys[j++] = i
	keys

Object.Extend = (a, b, k) -> # Object.Extend(a, b, [k]) - merge values from b into a
	# if k is present, it should be an array of property names
	if Object::toString.apply(k) is "[object Array]" # cant use Object.IsArray yet
		for i of k
			a[k[i]] = b[k[i]] unless b[k[i]] is undefined
	else
		for i in (k = Object.Keys(b))
			a[i] = b[i]
	a

Object.Extend Object,
	Type: (o) ->
		switch true
			when o is undefined then "undefined"
			when o is null then "null"
			when Object.IsString o then "string"
			when Object.IsArray o then "array"
			when Object.IsNumber o then "number"
			when Object.IsFragment o then "fragment"
			when Object.IsNode o then "node"
			when Object.IsFunc o then "function"
			when Object.IsType o, "RegExp" then "regexp"
			when String(o) in ["true", "false"] then "boolean"
			when Object.IsError o then "error"
			when Object.IsObject o
				if "setInterval" of o # same crude method that jQuery uses
					"window"
				else
					"object"
	IsType: (o,T) -> # Object.IsType(o,T) - true if object o is of type T (directly or indirectly)
		if o == null
			o is T
		else if o.constructor is T
			true
		else if typeof T is "string"
			o.constructor.name is T or Object::toString.apply(o).replace(OBJECT_RE, "$1") is T
		else
			Object.IsType o.__proto__, T # recurse through sub-classes
	IsString: (o) -> # Object.IsString(a) - true if object a is a string
		o? and (typeof o is "string" or Object.IsType(o, String))
	IsNumber: (o) ->
		o? and Object.IsType o, Number
	IsBoolean: (o) ->
		typeof o is "boolean"
	IsSimple: (o) ->
		Object.IsString(o) or Object.IsNumber(o) or Object.IsBoolean(o)
	IsFunc: (o) -> # Object.IsFunc(a) - true if object a is a function
		o? and (typeof o is "function" or Object.IsType(o, Function)) and o.call?
	IsNode: (o) -> # Object.IsNode(o) - true if object is a DOM node
		o? and o.nodeType > 0
	IsFragment: (o) -> # Object.IsFragment(o) - true if object is a DocumentFragment node
		o? and o.nodeType is 11
	IsArray: (o) -> # Object.IsArray(o) - true if object is an Array (or inherits Array)
		o? and (Object.ToString(o) is "[object Array]" or Object.IsType(o, Array))
	IsError: (o) ->
		o? and o.constructor?.name is "Error"
	IsObject: (o) -> # Object.IsObject(o) - true if a is an object
		o? and typeof o is "object" and Object.ToString(o) is "[object Object]"
	IsDefined: (o) -> # Object.IsDefined(o) - true if a is not null nor undefined
		o?
	Unbox: (a) -> # Object.Unbox(o) - primitive types can be 'boxed' in an object
		if a? and Object.IsObject(a)
			return a.toString() if Object.IsString a
			return Number(a) if Object.IsNumber a
		a
	ToString: (x) ->
		Object::toString.apply(x)
	Get: (o, k, d) -> # Object.Get(object, property, default)
		if not o?
			return d
		dot = k.indexOf '.'
		if dot > -1
			return Object.Get(Object.Get(o,k.slice(0,dot)),k.slice(dot+1), d)
		if o.hasOwnProperty(k) or (not Object.IsSimple(o) and k of o)
			return o[k]
		return d
	Compare: (a, b) -> # Object.Compare(a, b) - deep recursive comparison for arbitrary objects
		ta = Object.Type(a)
		tb = Object.Type(b)
		if ta isnt tb
			return false
		if ta is "array"
			if a.length isnt b.length
				return false
			for i in [0..a.length]
				if not Object.Compare(a[i],b[i])
					return false
		else if ta in ["string","number","boolean","function"]
			return a is b
		else if Object.IsObject(a)
			for k of a
				if not Object.Compare(a[k],b[k])
					return false
		return true

Object.Extend Function,
	Empty: () -> # the empty function
	Bound: (f, t, args = []) -> # Function.Bound(/f/, /t/) - whenever /f/ is called, _this_ is /t/
		if "bind" of f
			args.splice 0, 0, t
			r = f.bind.apply f, args
		else
			r = (a...) ->
				if args.length > 0
					a = args
				f.apply t, args
		r.toString = () ->
			"bound-method of #{t}.#{f.name}"
		r
	Trace: (f, label, tracer = log) -> # Function.Trace(/f/, /label/) - log calls to /f/
		r = (a...) ->
			tracer "#{@name or Object.Type(@)}.#{label or f.name}(", a, ")"
			f.apply @, a
		tracer "Function.Trace: #{label or f.name} created."
		r.toString = f.toString
		r
	NotNull: (x) -> x != null
	NotEmpty: (x) -> x not in ["", null]
	IndexFound: (x) -> x > -1
	ReduceAnd: (x) -> x and @
	UpperLimit: (x) -> (y) -> Math.min(x, y)
	LowerLimit: (x) -> (y) -> Math.max(x, y)
	Px: (d) -> () -> Number.Px(@,d)

Object.Extend Array,
	Coalesce: (a...) ->
		# Array.Coalesce - returns the first non-null argument
		if Object.IsArray(a[0])
			Array.Coalesce a[0]...
		else
			for i in a
				return i if i?
	Extend: (a, b) ->
		j = a.length
		for i in b
			a[j++] = i
		a
	Compact: (a, s = "", r = []) ->
		if Object.IsSimple(a) or not Object.IsArray(a)
			return a
		for i in a
			if not Object.IsDefined(i) then continue
			else if Object.IsSimple(i) then s += i
			else if Object.IsArray(i)
				ret = Array.Compact(i, s, r)
				if Object.IsString(ret)
					s = ret
				else if Object.IsArray(ret)
					r = ret
					s = ""
			else
				if s.length > 0
					r.push s
					s = ""
				r.push i
		if r.length is 0
			return s
		if s.length > 0
			r.push s
		return r

Object.Extend Number,
	Px: (x, d=0) ->
		# Px(/x/, /delta/=0) - convert a number-ish x to pixels
		x? and (parseInt(x,10)+(d|0))+"px"
	# mappable versions of max() and min()
	AtLeast: (x) ->
		(y) ->
			Math.max parseFloat(y or 0), x
	AtMost: (x) ->
		(y) ->
			Math.min parseFloat(y or 0), x

Object.Extend String,
	PadLeft: (s, n, c = " ") -> # String.PadLeft(string, width, fill=" ")
		while s.length < n
			s = c + s
		s
	PadRight: (s, n, c = " ") -> # String.PadRight(string, width, fill=" ")
		while s.length < n
			s = s + c
		s
	Splice: (s, i, j, n) -> # String.Splice(string, start, end, n) - replace a substring with n
		nn = s.length
		end = j
		if end < 0
			end += nn
		start = i
		if start < 0
			start += nn
		s.substring(0,start) + n + s.substring(end)
	Checksum: (s) -> # String.Checksum(string) - Adler32 checksum of a string
		a = 1; b = 0
		for i in [0...s.length]
			a = (a + s.charCodeAt(i)) % 65521
			b = (b + a) % 65521
		return (b << 16) | a

