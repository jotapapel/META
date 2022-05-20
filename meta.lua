local meta = {}
local patterns = {
	inline = {
		-- local variables
		["^let(%s+.-)$"] = "local%1",
		-- global variables
		["^var%s+(.-)%s+=%s+(.-)$"] = function(a, b)
			a = string.gsub(string.format("%s,", a), "(.-),", function(c) return string.format("_G[\"%s\"],", c) end):sub(1, -2)
			return string.format("%s = %s", a, b)
		end,
		-- variable transform (string)
		["$([_%a][_%w%.%[%]\"]*)"] = "tostring(%1)",
		-- inline functions as arguments
		["%b()"] = function(a)
			local b, c = meta.capture(a:match("^%((.-)%)$") .. ",", "%b()", "<ARGUMENTS%s>")
			b = b:gsub("%s*(.-),%s*", function(d)
				local e, f = d:match("^(<ARGUMENTS%x+>):%s+(.-)$")
				if e and f then d = string.format("function%s %s end", e, f) end
				return string.format("%s, ", d)
			end)
			return string.format("(%s)", meta.release(b, c):match("(.-),%s*$"))
		end,
		-- inline if-else
		["^(.-)%s+if%s+(.-)%s+else%s+(.-)$"] = function(a, b, c)
			return string.format("if %s then %s else %s end", b, a, c)
		end,
		["^(.-)%s+if%s+(.-)$"] = function(a, b)
			return string.format("if %s then %s end", b, a)
		end,
	},
	decorators =  {
		["@weak"] = function(a)
			return string.gsub(a, "%((.-)%)", "(!%1)")
		end,
		["@private"] = function(a)
			return string.gsub(a, "([_%a][_%.%w]*%(.-%):)", "let %1")
		end
	},
	openings = {
		-- prototypes
		["^def%s+([_%a][_%.%w]*){(.-)}:$"] = function(a, b) 
			return a .. " = prototype.extend(" .. (#b > 0 and b or "nil") .. ", function()" 
		end,
		["^([_%a][_%.%w]*)%s+=%s+{(.-)}:$"] = function(a, b) 
			return a .. " = prototype.extend(" .. (#b > 0 and b or "nil") .. ", function()" 
		end,
		-- methods
		["([_%a][_%.%w]*)%((.-)%):$"] = function(a, b)
			local c, d = b:match("^(!?)(.-)$")
			if #c == 0 then d = "self" .. (#d > 0 and ", " or "")  .. d end
			return a .. " = function(" .. d .. ")"
		end,
		-- functions
		["^def%s+([_%a][_%.%w]*%(.-%)):$"] = "function %1",
		["^(.-%s+)(%(.-%)):$"] = "%1function%2",
		-- control structures
		["^if%s+(.-):$"] = "if %1 then",
		["^elseif%s+(.-):$"] = "elseif %1 then",
		["^else:$"] = "else",
		["^for%s+(.-):$"] = "for %1 do",
		["^while%s+(.-):$"] = "while %1 do",
		["^until%s+.-:$"] = "repeat"
	},
	closings = {
		["^def%s+[_%a][_%.%w]*{.-}:$"] = "end)",
		["^until%s+(.-):$"] = "until %s"
	}
}

--- Dump the contents of a file on to a table.
-- @param a	string The path to the file.
-- @return table	The table containing the lines of said file.
meta.readfile = function(a)
	local b, c = io.open(a, "r"), {}
	if b then
		for d in io.lines(a) do
			table.insert(c, d)
		end
		b:close()
	end
	return c
end

---	Capture a string token, place it on a table and replace it on the original string with a special keyword.
-- @param a	string The string from wich we will extract the tokens.
-- @param b	string The token to find.
-- @param c	string The keyword to replace the tokens with.
-- @param d	function An optional function that will receive the token as it's only argument.
-- @returns	table, string	Returns a table containing the captured tokens and the newly modified string.
meta.capture = function(a, b, c, d)
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
meta.release = function(a, ...)
	local b, c = {...}, 0
	local d = table.remove(b)
	while d do
		local e = string.format("%s%02i", tostring(d):sub(-5), c)
		local f, g = a:match("^(.-)" .. string.format(d.b, e) .. "(.-)$")
		if c < d.a then a, c = (f or "") .. d[e] .. (g or ""), c + 1 else c, d = 0, table.remove(b) end
	end
	return a
end

--- Transform array declarations from '[key: value]' to '{key = value}'
-- Also it transforms declarations like '[1: value, "key": value]' to '{[1] = value, ["key"] = value}'
-- @param a	string The string to modify.
-- @returns	string The modified string.
meta.totable = function(a)
	local b, c = meta.capture(a:sub(2, -2), "%b[]", "<ARRAY%s>", meta.totable)
	local d = {}
	for e in string.gmatch(string.format("%s,", b), "(.-),%s*") do
		local f, g = e:match("^(.-):") or e, e:match(":%s+(.-)$")
		if g then
			if f:match([[%b""]]) or tonumber(f) then f = string.format("[%s]", f) end
			f = string.format("%s = %s", f, g)
		end
		table.insert(d, f)
	end
	return string.format("{%s}", meta.release(table.concat(d, ", "), c))
end

--- Replace variable insertions inside a string.
-- It transforms 'print("my ${var}")' -> 'print(string.interpolate("my %s", var))'
-- @param	a	string The string to modify.
-- @returns	string The modified string.
meta.interpolate = function(a)
	local b = {}
	a = a:gsub("$%{([_%a][_%.%w]*)}", function(c) table.insert(b, c) return "%s" end)
	return #b > 0 and string.format("string.interpolate(%s, %s)", a, table.concat(b, ", ")) or a
end

--- Generates closings according to the indentation of a string.
-- @param a	string The string to evaluate.
-- @param b	table	The table containing the closing level and string.
meta.generateclosing = function(a, b)
	local c = "end"
	for d, e in pairs(patterns.closings) do
		local f = a:match(d)
		if f then c = string.format(e, f) end
	end
	b[b.level + 1], b.level = c, b.level + 1 
end

--- Reform the string from meta to Lua.
-- @param a string The string to evaluate.
-- @param b table	The table containing the reform strings (the key should be the match string and the value it's replacement).
-- @param c string Optional inline meta code.
-- @returns	string The modified string.
meta.reform = function(a, b, c)
	for d, e in pairs(b) do
		a = a:gsub(d, e)
	end
	if type(c) == "string" then
		return a .. meta.reform(c, b) .. " end"
	end
	return a
end

--- Apply decorators.
-- @param a string The string to evaluate.
-- @param b table The file lines.
-- @param c number The current line index.
-- @return string, table The modified line and the modified file lines.
meta.decorate = function(a, b, c)
	local d = false
	for e, f in pairs(patterns.decorators) do
		if a:match(e) then d, b[c + 1] = true, f(b[c + 1]) end
	end
	return d and "" or a, b
end

--- Load a .mlua file and transpile it into Lua.
-- @param a string Path to the file.
-- @param b table Optional arguments.
-- @return table A table containing the new lines of Lua code.
meta.load = function(a)
	local file_lines, new_lines, closings, indent = meta.readfile(a), {}, {level = -1}, 0
	for index, raw_line in ipairs(file_lines) do
		local level, line, comment = raw_line:match("^(%s*)"):len(), raw_line:match("^%s*(.-)%s*$"), ""
		-- capture
		local ca, cb, cc, cd
		line, ca = meta.capture(line, "\\.", "<CHAR%s>")
		line, cb = meta.capture(line, [[%b""]], "<STRING%s>", meta.interpolate)
		line, cc = meta.capture(line, "([_%a][_%w%.]*%b[])", "<ARRAYVAR$>")
		line, cd = meta.capture(line, "%b[]", "<ARRAY%s>", meta.totable)
		line = meta.capture(line, "'(.-)$", "", function(a) comment = string.format("--%s", a) end)
		-- decorators
		line, file_lines = meta.decorate(line, file_lines, index)
		-- closings
		while level <= closings.level and (#line > 0 or #comment > 0) do
			local no_indent = line:match("^elseif%s+.-:$") or line:match("^else:$")
			closings.level, indent = closings.level - 1, indent - (no_indent and 0 or 1)
			if not no_indent then table.insert(new_lines, string.rep("\t", indent) .. closings[closings.level + 1]) end
		end
		-- reform
		line = meta.reform(line, patterns.inline)
		local head, tail = line:match("(.-:)%s+") or line:match("(.-:)$"), line:match(":(%s+.-)$")
		if head then
			if not tail then meta.generateclosing(head, closings) end
			line = meta.reform(head, patterns.openings, tail)
		end
		-- release
		line = meta.release(line, ca, cb, cc, cd)
		-- indent
		local scafold_line = line:gsub("%b{}", "<a/>"):gsub("%b()", "<b/>"):gsub("function<b/>.-end", "<c/>"):gsub("function%s+.-<b/>.-end", "<c/>")
		if scafold_line:match("^until.-$") or scafold_line:match("^end.-$") or scafold_line:match("^elseif%s+.-%s+then$") or scafold_line:match("^else$") or scafold_line:match("^%s*}%s*.-$") then indent = indent - 1 end
		if #line > 0 or #comment > 0 then table.insert(new_lines, string.rep("\t", indent) .. line .. comment) end
		if scafold_line:match("^while%s+.-%s+do$") or scafold_line:match("^repeat$") or scafold_line:match("^.-%s*function<b/>$") or scafold_line:match("^.-%s*function%s+.-$") or scafold_line:match("^.-%s+then$") or scafold_line:match("^else$") or (scafold_line:match("^.-do$") and not scafold_line:match("^.-end.-$")) or scafold_line:match("^.-%s*{%s*$") then indent = indent + 1 end
	end
	-- final closings
	while closings.level > -1 do
		table.insert(new_lines, string.rep("\t", closings.level) .. closings[closings.level])
		closings.level = closings.level - 1
	end
	return new_lines
end

-- transpile test file
local lua_file = meta.load("main.mlua")
for p, q in ipairs(lua_file) do
	print(q)
end