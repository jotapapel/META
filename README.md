# 🔡 Tile
**Ti**ny scripting **l**anguag**e** that compiles to Lua.

- [x] Comments
- [x] Basic control structures (if-elseif-else, while, for, repeat)
- [x] Prototype declarations
- [x] Function declarations, function expressions, functions as arguments
- [x] Arrays

#### Example code
`````
/* Simple prototype declaration */
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
-- Simple object declartion
Object = tile.prototype(function()
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
