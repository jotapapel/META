local lexer = require "lexer"
local parser = {}

---	Capture a string token, place it on a table and replace it on the original string with a special keyword.
-- @param a	string The string from wich we will extract the tokens.
-- @param b	string The token to find.
-- @param c	string The keyword to replace the tokens with.
-- @param d	function An optional function that will receive the token as it's only argument.
-- @returns	table, string	Returns a table containing the captured tokens and the newly modified string.
parser.capture = function(a, b, c, d)
	local e = {a = 0, b = c}
	a = a:gsub(b, function(f)
		local g = string.format("%s%02i", tostring(e):sub(-5), e.a)
		e[g], e.a = (type(d) == "function" and d(f)) or f, e.a + 1
		return string.format(c, g)
	end)
	return a, e
end

--- Release all tokens from a previously captured token table on to the original string from which they were captured.
-- @param a	string The string that had it's tokens captured.
-- @param ... The tables containing the captured tokens.
-- @return string The string with it's original tokens.
parser.release = function(a, ...)
	local b, c = {...}, 0
	local d = table.remove(b)
	while d do
		local e = string.format("%s%02i", tostring(d):sub(-5), c)
		local f, g = a:match("^(.-)" .. string.format(d.b, e) .. "(.-)$")
		if c < d.a then a, c = (f or "") .. d[e] .. (g or ""), c + 1 else c, d = 0, table.remove(b) end
	end
	return a
end

--- Generates closings according to the indentation of a string.
-- @param a	string The string to evaluate.
-- @param b	table	The table containing the closing level and string.
-- @param c	table	The table containing information about the structure we are currently in.
parser.close = function(a, b, c)
	local d = "end"
	for e, f in pairs(lexer.closings) do
		local g = a:match(e)
		if g then d = string.format(f, g) end
	end
	b[b.level + 1], b.level = d, b.level + 1
	if d == "<end)>" then c[b.level + 1] = "prototype" end
	return ""
end

--- Reform the string from meta to Lua.
-- @param a string The string to evaluate.
-- @param b table	The table containing the reform strings (the key should be the match string and the value it's replacement).
-- @param c string Optional inline meta code.
-- @returns	string The modified string.
parser.parse = function(a, b, c)
	b = lexer[b]
	for d, e in pairs(b) do
		a = a:gsub(d, e)
	end
	if type(c) == "string" then
		local f, g = c:match("^(.-:)%s+") or c:match("^(.-:)$") or c, c:match(":%s+(.-)$")
		return string.format("%s %s end", a, parser.parse(f, "openings", g))
	end
	return a
end

return parser