# 🔡 Tile
**Ti**ny scripting **l**anguag**e** inspired by Python that compiles to Lua.

- [x] Comments
- [x] Basic control structures (if-elseif-else, while, for, repeat)
- [x] Prototype declarations.
- [x] Function declarations, function expressions, functions as arguments.
- [x] Arrays

#### Example code
`````
' Simple prototype declaration
Object = {}:
	x, y = 0, 0
	init = (self, x, y):
		self.x, self.y = x, y
	locate = (self):
		print(self.x, self.y)

Player = {Object}:
	locate = (self):
		print("Player location is:")
		super.locate(self)

let objectIndex = []
for index = 1, 10:
	objectIndex[index] = Object(math.random(0, 240), math.random(0, 136))

main = ():
	for index, object in pairs(objectIndex):
		object:locate()
`````

#### Lua equivalent
````` lua
lang = (function()
	local new = function(a, ...) local b = setmetatable({super = a}, {__index = a}) if a.init then a.init(b, ...) end return b end
	local prototype = function(a, b) local c, d, e = b and a, b or a, 1; local f = setmetatable({super = c}, {__index = c, __call = new}); local g = setmetatable({self = f, super = c}, {__index = _G, __newindex = f}) repeat local h = debug.getupvalue(d, e) if h == "_ENV" then debug.upvaluejoin(d, e, function() return g end, 1) break end e = e + 1 until not h; d() return f end
	local object = prototype(function() get = function(a, b) return a[b] end; set = function(a, b, c) if type(b) == "table" then for d, e in pairs(b) do a[d] = e end elseif type(b) == "string" then a[b] = c end end end)
	return {prototype = prototype, object = object}
end)()
-- Simple object declartion
Object = lang.prototype(function()
	x, y = 0, 0
	init = function(self, x, y)
		self.x, self.y = x, y
	end
	locate = function(self)
		print(self.x, self.y)
	end
end)
Player = tile.prototype(Object, function()
	locate = function(self)
		print("Player location is:")
		super.locate(self)
	end
end)
local objectIndex = {}
for index = 1, 10 do
	objectIndex[index] = Object(math.random(0, 240), math.random(0, 136))
end
main = function()
	for index, object in pairs(objectIndex) do
		object:locate()
	end
end
`````
