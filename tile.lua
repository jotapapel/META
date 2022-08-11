local parser = require "parser"
local config = {tab_size = 1, comments = true, indent_char = "\t"}
local tile = {}

--- Dump the contents of a file on to a table.
--- @param a string The path to the file.
--- @return table # The table containing the lines of said file.
tile.readfile = function(a)
	local b <close>, c = io.open(a, "r"), {}
	if b then 
		for d in io.lines(a) do table.insert(c, d) end
		return c
	end
	return false
end

--- Add the library when needed.
--- @param a table The new lines table.
--- @return boolean # Returns true when added.
tile.loadlang = function(a)
	local b = tile.readfile("lib.lua")
	table.insert(a, 1, table.concat(b, "\n"))
	return true
end

--- Replace variable insertions inside a string.
--- It transforms "my ${var}" to string.format("my %s", tostring(var))
--- @param a string The string to modify.
--- @return	string # The modified string.
tile.interpolate = function(a)
	local b = {}
	a = string.gsub(a, "${(.-)}", function(c) table.insert(b, string.format("tostring(%s)", c)) return "%s" end)
	return #b > 0 and string.format("string.format(%s, %s)", a, table.concat(b, ", ")) or a
end

--- Replace special keywords inside parenthesis.
--- @param a string The string to be evaluated.
--- @return string # The modified string.
tile.parenthesis = function(a)
	local b, c = parser.capture(string.sub(a, 2, -2), "%b()", "<PARENTHESIS%s>", tile.parenthesis)
	local d = parser.eacha(b, function(e) return parser.parse(e, "inline") end)
	return string.format("(%s)", parser.release(d, c))
end

--- Transform array declarations from '[key: value]' to '{key = value}'.
--- Also it transforms declarations like '[1: value, "key": value]' to '{[1] = value, ["key"] = value}'
--- It also changes some special keywords in the "inline" part of the lexer.
--- @param a string The string to modify.
--- @return	string # The modified string.
tile.brackets = function(a)
	local b, c = parser.capture(string.sub(a, 2, -2), "%b[]", "<TABLE%s>", tile.totable)
	local d = parser.eacha(b, function(e)
		local f, g = string.match(e, "^(.-):") or e, string.match(e, ":%s+(.-)$")
		if g then
			if string.match(f, [[%b""]]) or tonumber(f) then f = string.format("[%s]", f) end
			return string.format("%s = %s", f, parser.parse(g, "inline"))
		end
	end)
	return string.format("{%s}", parser.release(d, c))
end

--- Replace special keywords in variable declarations.
--- @param a string The variable names, separated by commas.
--- @param b string (optional) An operator for quick math operations.
--- @param c string The variable values, separated by commas.
--- @return string # The modified string.
tile.expressions = function(a, b, c)
	local d, e = string.match(a, "^(%w+%s+)(.-)$")
	local f = parser.eacha(e or a, true)
	local g = parser.eacha(c, function(h, i)
		h = parser.parse(h, "inline")
		if #b > 0 then h = string.format("%s %s %s", f[i], b, h) end
		return h
	end)
	return string.format("%s%s = %s", d or "", table.concat(f, ", "), g)
end

--- Load a Tile file and transpile it into vanilla Lua.
--- @param a string Path to the file.
--- @return table # A table containing the new lines of Lua code.
tile.transpile = function(a)
	local file_lines, new_lines, lib_lines = tile.readfile(a), {}, false
	local indent_table, structure_table = {current = 0, last = -1}, {}
	for _, raw_line in ipairs(file_lines) do
		local raw_level = string.len(string.match(raw_line, "^(%s*)"))
		local line, comment = string.match(raw_line, "^%s*(.-)%s*$"), ""
    -- comments
    line = string.gsub(line, "'(.-)$", function(a) comment = string.format("--%s", a) return "" end)
		-- capture
		local ca, cb, cc, cd, ce, cf
		line, ca = parser.capture(line, "\\.", "<CHAR%s>")
		line, cb = parser.capture(line, [[%b""]], "<STRING%s>", tile.interpolate)
		line, cc = parser.capture(line, "%b():[^$]", "<INLINE_FUNCTION%s>", function(a) return string.format("function(%s)", string.sub(a, 2, -4)) end)
		line, cd = parser.capture(line, "[_%w%)%]]%b[]", "<TABLE_INDEX%s>")
		line, ce = parser.capture(line, "<INDEX.->%b[]", "<TABLE_INDEX%s>")
		line, cf = parser.capture(line, "%b[]", "<TABLE%s>")
		-- closings
		while raw_level <= indent_table.last and (string.len(line) > 0 or string.len(comment) > 0) do
			local no_indent = (string.match(line, "^elseif%s+.-:$") or string.match(line, "^else:$")) and indent_table[indent_table.last] == "<end>"
			indent_table.last, indent_table.current = indent_table.last - 1, indent_table.current - (no_indent and 0 or 1)
			if not no_indent then
				table.insert(new_lines, string.rep(config.indent_char, indent_table.current * config.tab_size) .. string.gsub(indent_table[indent_table.last + 1], "<(.-)>", "%1"))
			end
		end
		-- main substitutions
		line = parser.parse(line, "substitutions")
		local head, tail = string.match(line, "(.-:)%s*"), string.match(line, ":%s+(.-)$")
		if head then
			if not tail then parser.close(head, indent_table, structure_table) end
			line = parser.parse(head, "openings", tail)
		end
		-- special substitutions
		local sa, sb, sc
		line = parser.release(line, cf)
		line, sa = parser.capture(line, "%b()", "<PARENTHESIS%s>", tile.parenthesis)
		line, sb = parser.capture(line, "%b[]", "<TABLE%s>", tile.brackets)
		line = string.gsub(line, "^([%w_%.%s,]*)%s+([%+%-%*%/%^]*)=%s*(.-)$", tile.expressions)
		if structure_table[indent_table.last + 1] == "prototype" and not lib_lines then lib_lines = tile.loadlang(new_lines) end
		-- release all captures
		line = parser.release(line, ca, cb, cc, cd, ce, sa, sb)
		-- indent
		local scafold_line = string.gsub(line, "%b{}", "<table/>"):gsub("%b()", "<parenthesis/>"):gsub("function<parenthesis/>.-end", "<function/>"):gsub("function%s+.-<parenthesis/>.-end", "<function/>")
		if scafold_line:match("^until.-$") or scafold_line:match("^end.-$") or scafold_line:match("^elseif%s+.-%s+then$") or scafold_line:match("^else$") or scafold_line:match("^%s*}%s*.-$") then indent_table.current = indent_table.current - 1 end
		if string.len(line) > 0 or string.len(comment) > 0 then table.insert(new_lines, string.rep(config.indent_char, indent_table.current * config.tab_size) .. line .. comment) end
		if scafold_line:match("^while%s+.-%s+do$") or scafold_line:match("^repeat$") or scafold_line:match("^.-%s*function<parenthesis/>$") or scafold_line:match("^.-%s*function%s+.-$") or scafold_line:match("^.-%s+then$") or scafold_line:match("^else$") or (scafold_line:match("^.-do$") and not scafold_line:match("^.-end.-$")) or scafold_line:match("^.-%s*{%s*$") then indent_table.current = indent_table.current + 1 end
	end
	-- final closings
	while indent_table.last > -1 do
		local key = string.gsub(indent_table[indent_table.last], "<(.-)>", "%1")
		table.insert(new_lines, string.rep(config.indent_char, indent_table.last * config.tab_size) .. key)
		indent_table.last = indent_table.last - 1
	end
	return new_lines
end

local name, options = ...

-- transpile a single file
if string.match(name, "^.-%/[%.%w_]+%.tle$") then

elseif string.match(name, "%/[%w_]+$") goto
	local config_file = tile.readfile("tleconfig.lua")
end