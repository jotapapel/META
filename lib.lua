lang = {}
lang.new = function(a, ...)
	local b = setmetatable({super = a}, {__index = a})
	if a.init then a.init(b, ...) end
	return b
end
lang.prototype = function(a, b)
	local c, d, e = b and a, b or a, 1
	local f = setmetatable({super = c}, {__index = c, __call = tile.new})
	local g = setmetatable({self = f, super = c}, {__index = _G, __newindex = f})
	repeat
		local h = debug.getupvalue(d, e)
		if h == "_ENV" then 
			debug.upvaluejoin(d, e, function() return g end, 1)
			break
		else
			e = e + 1
		end
	until not h
	d()
	return f
end
lang.object = tile.prototype(function()
	get = function(a, b)
		return a[b]
	end
	set = function(a, b, c)
		if type(b) == "table" then
			for d, e in pairs(b) do
				a[d] = e
			end
		elseif type(b) == "string" then
			a[b] = c
		end
	end
end)