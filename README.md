# 🧀 Cheese
Tiny language that compiles to lua.

#### Example code
`````
def Object{}:
	x, y = 0, 0
	constructor(x, y):
		self.x, self.y = x, y
	locate():
		console.log(self.x, self.y)

let objectIndex = []
for index = 1, 10:
	objectIndex[index] = Object(Math.random(0, 320), Math.random(0, 240))

fn main():
	console.clear()
	for index, object in Array.each(objectIndex):
		object:locate()
`````
