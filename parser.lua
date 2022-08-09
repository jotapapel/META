local lexer = require "lexer"
local parser = {}

---	Capture a string token, place it on a table and replace it on the original string with a special keyword.
--- @param a string The string from wich we will extract the tokens.
--- @param b string The token to find.
--- @param c string The keyword to replace the tokens with.
--- @param d? function An optional function that will receive the token as it's only argument.
--- @return	string, table	# Returns first the modified string and second table containing the captured tokens.
parser.capture = function(a, b, c, d)
	local e = {a = 0, b = c}
	a = string.gsub(a, b, function(f)
		local g = string.format("%s%02i", tostring(e):sub(-5), e.a)
		e[g], e.a = type(d) == "function" and d(f) or f, e.a + 1
		return string.format(c, g)
	end)
	return a, e
end

--- Release all tokens from a previously captured token table on to the original string from which they were captured.
--- @param a string|table The string that had it's tokens captured.
--- @param ... table The tables containing the captured tokens.
--- @return string # The string with it's original tokens.
parser.release = function(a, ...)
	local b, c = {...}, 0
	local d = table.remove(b)
	while d do
		local e = string.format("%s%02i", string.sub(tostring(d), -5), c)
		local f, g = a:match("^(.-)" .. string.format(d.b, e) .. "(.-)$")
		if c < d.a then a, c = string.format("%s%s%s", f or "", d[e], g or ""), c + 1 else c, d = 0, table.remove(b) end
	end
	return a
end

--- Generates closings according to the indentation of a string.
--- @param a string The string to evaluate.
--- @param b table The table containing the closing level and string.
--- @param c table The table containing information about the structure we are currently in.
parser.close = function(a, b, c)
	local d = "end"
	for e, f in pairs(lexer.closings) do
		local g = string.match(a, e)
		if g then d = string.format(f, g) end
	end
	b[b.last + 1], b.last = d, b.last + 1
	if d == "<end)>" then c[b.last + 1] = "prototype" end
	return ""
end

--- Reform the string from Tile to Lua.
--- @param a string The string to evaluate.
--- @param b string|table	The name of the key inside the lexer used to evaluate.
--- @param c? string Optional inline code.
--- @return	string The modified string.
parser.parse = function(a, b, c)
	b = lexer[b]
	for d, e in pairs(b) do a = string.gsub(a, d, e) end
	if type(c) == "string" then
		local f, g = string.match(c, "^(.-:)%s+") or string.match(c, "^(.-:)$") or c, string.match(c, ":%s+(.-)$")
		return string.format("%s %s end", a, parser.parse(f, "openings", g))
	end
	return a
end

--- Iterate thru arguments (list of items separated by commas).
--- @param a string The string to iterate.
--- @param b? function|boolean Optional function that accepts a single argument (the found iterated string), or flag to return the table instead of a string. 
--- @return string|table # String or table with the done iteration.
parser.eacha = function(a, b, c)
	local d, e = 0, {}
	for f in string.gmatch(string.format("%s,", a), "(.-),%s*") do
		d = d + 1
		table.insert(e, type(b) == "function" and b(f, d) or f)
	end
	return (c or b == true) and e or table.concat(e, ", ")
end

return parser