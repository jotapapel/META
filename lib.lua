lang = (function()
	local new = function(a, ...) local b = setmetatable({super = a}, {__index = a}) if a.__init then a.__init(b, ...) end return b end
	local prototype = function(a, b) local c, d, e = b and a, b or a, 1; local f = setmetatable({super = c}, {__index = c, __call = new}); local g = setmetatable({self = f, super = c}, {__index = _G, __newindex = f}) repeat local h = debug.getupvalue(d, e) if h == "_ENV" then debug.upvaluejoin(d, e, function() return g end, 1) break end e = e + 1 until not h; d() return f end
	local object = prototype(function() get = function(a, b) return a[b] end; set = function(a, b, c) if type(b) == "table" then for d, e in pairs(b) do a[d] = e end elseif type(b) == "string" then a[b] = c end end end)
	return {prototype = prototype, object = object}
end)()