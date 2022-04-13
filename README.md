# 🧀 Cheese
Tiny language that compiles to lua.

#### Example code
`````
def Object{}:
	x, y = 0, 0
	constructor(x, y):
		self.x, self.y = x, y
	locate():
		print(self.x, self.y)

let objectIndex = []
for index = 1, 10:
	objectIndex[index] = Object(Math.random(0, 320), Math.random(0, 240))

fn main():
	for index, object in pairs(objectIndex):
		object:locate()
`````

#### Lua equivalent
`````` lua
Object = cheese.prototype(function()
	x, y = 0, 0
	constructor = function(self, x, y)
		self.x, self.y = x, y
	end
	locate = function(self)
		print(self.x, self.y)
	end
end)
local objectIndex = {}
for index = 1, 10 do
	objectIndex[index] = Object(math.random(0, 320), math.random(0, 240))
end
function main()
	for index, object in pairs(objectIndex) do
		object:locate()
	end
end

