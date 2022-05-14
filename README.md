# META (Minimal Expression Transpile Algorithm)
Tiny language that compiles to lua.

- [x] Inline comments
- [x] Basic control structures (if-elseif-else, while, for)
- [x] Prototype declarations
- [x] Function declarations, function expressions
- [x] Inline array declaration

#### Example code
`````
def Object{}:
	x, y = 0, 0
	init(x, y):
		self.x, self.y = x, y
	locate():
		print(self.x, self.y)

let objectIndex = []
for index = 1, 10:
	objectIndex[index] = Object(math.random(0, 240), math.random(0, 136))

def main():
	for index, object in pairs(objectIndex):
		object:locate()
`````

#### Lua equivalent
````` lua
Object = prototype.extend(nil, function()
	x, y = 0, 0
	init = function(self, x, y)
		self.x, self.y = x, y
	end
	locate = function(self)
		print(self.x, self.y)
	end
end)
local objectIndex = {}
for index = 1, 10 do
	objectIndex[index] = Object(math.random(0, 240), math.random(0, 136))
end
function main()
	for index, object in pairs(objectIndex) do
		object:locate()
	end
end
`````
