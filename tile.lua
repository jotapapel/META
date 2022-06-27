package.path = debug.getinfo(1).source:match("@?(.*/)") .. "?.lua;" .. package.path

local path, arg1 = ...
local parser = require "parser"

local status, config
if string.match(path, ".-%.tl$") then
	config = {tab_size = 1, comments = true}
elseif string.match(path, ".-%/.-%/?$") then
	print("Directory found (" .. path .. ").")
	status, config = pcall(require, "tlconfig")
	if status then
		print("1. tlconfig file found...")
		config.tab_size = config.tab_size
		config.comments = config.comments
	else
		error("No tlconfig.lua file found on current directory.", 0)
	end
end

--- Dump the contents of a file on to a table.
-- @param a	string The path to the file.
-- @return table	The table containing the lines of said file.
local readfile = function(a)
	local b, c = io.open(a, "r"), {}
	if b then
		for d in io.lines(a) do
			table.insert(c, d)
		end
		b:close()
	end
	return c
end

local utils = {}

--- Transform array declarations from '[key: value]' to '{key = value}'
-- Also it transforms declarations like '[1: value, "key": value]' to '{[1] = value, ["key"] = value}'
-- @param a	string The string to modify.
-- @returns	string The modified string.
utils.totable = function(a)
	local b, c = parser.capture(a:sub(2, -2), "%b[]", "<ARRAY%s>", utils.totable)
	local d = {}
	for e in string.gmatch(string.format("%s,", b), "(.-),%s*") do
		local f, g = e:match("^(.-):") or e, e:match(":%s+(.-)$")
		if g then
			if f:match([[%b""]]) or tonumber(f) then f = string.format("[%s]", f) end
			f = string.format("%s = %s", f, g)
		end
		table.insert(d, f)
	end
	return string.format("{%s}", parser.release(table.concat(d, ", "), c))
end

--- Replace variable insertions inside a string.
-- It transforms 'print("my ${var}")' -> 'print(string.format("my %s", tostring(var)))'
-- @param	a	string The string to modify.
-- @returns	string The modified string.
utils.interpolate = function(a)
	local b = {}
	a = a:gsub("$%{([_%a][_%.%w]*)}", function(c) table.insert(b, string.format("tostring(%s)", c)) return "%s" end)
	return #b > 0 and string.format("string.format(%s, %s)", a, table.concat(b, ", ")) or a
end

--- Load a .mlua file and transpile it into Lua.
-- @param a string Path to the file.
-- @param b table Optional arguments.
-- @return table A table containing the new lines of Lua code.
local transpile = function(a)
	local file_lines, new_lines, indent, closings, inside_of = readfile(a), {}, 0, {level = -1}, {}
	for index, raw_line in ipairs(file_lines) do
		local level, line, comment = raw_line:match("^(%s*)"):len(), raw_line:match("^%s*(.-)%s*$"), ""
		-- capture
		local ca, cb, cc, cd
		line, ca = parser.capture(line, "\\.", "<CHAR%s>")
		line, cb = parser.capture(line, [[%b""]], "<STRING%s>", utils.interpolate)
		line, cc = parser.capture(line, "([_%a][_%w%.]*%b[])", "<ARRAYVAR$>")
		line, cd = parser.capture(line, "%b[]", "<ARRAY%s>", utils.totable)
		line = parser.capture(line, "%*%*(.-)$", "", function(a) comment = string.format("--%s", a) end)
		-- closings
		while level <= closings.level and (#line > 0 or #comment > 0) do
			local no_indent = (line:match("^elseif%s+.-:$") or line:match("^else:$")) and closings[closings.level] == "<end>"
			closings.level, indent = closings.level - 1, indent - (no_indent and 0 or 1)
			if not no_indent then
				table.insert(new_lines, string.rep("\t", indent * config.tab_size) .. closings[closings.level + 1]:gsub("<(.-)>", "%1"))
			end
		end
		-- line transpile
		line = parser.parse(line, "substitutions")
		local head, tail = line:match("(.-:)%s+") or line:match("(.-:)$"), line:match(":%s+(.-)$")
		if head then
			if not tail then parser.close(head, closings, inside_of) end
			line = parser.parse(head, "openings", tail)
		end
		-- release
		line = parser.release(line, ca, cb, cc, cd)
		-- indent
		local scafold_line = line:gsub("%b{}", "<a/>"):gsub("%b()", "<b/>"):gsub("function<b/>.-end", "<c/>"):gsub("function%s+.-<b/>.-end", "<c/>")
		if scafold_line:match("^until.-$") or scafold_line:match("^end.-$") or scafold_line:match("^elseif%s+.-%s+then$") or scafold_line:match("^else$") or scafold_line:match("^%s*}%s*.-$") then indent = indent - 1 end
		if #line > 0 or #comment > 0 then table.insert(new_lines, string.rep("\t", indent * config.tab_size) .. line .. comment) end
		if scafold_line:match("^while%s+.-%s+do$") or scafold_line:match("^repeat$") or scafold_line:match("^.-%s*function<b/>$") or scafold_line:match("^.-%s*function%s+.-$") or scafold_line:match("^.-%s+then$") or scafold_line:match("^else$") or (scafold_line:match("^.-do$") and not scafold_line:match("^.-end.-$")) or scafold_line:match("^.-%s*{%s*$") then indent = indent + 1 end
	end
	-- final closings
	while closings.level > -1 do
		local closing = closings[closings.level]:gsub("<(.-)>", "%1")
		table.insert(new_lines, string.rep("\t", closings.level * config.tab_size) .. closing)
		closings.level = closings.level - 1
	end
	return new_lines
end

local final_lines = readfile(debug.getinfo(1).source:match("@?(.*/)") .. "lib.min.lua")

-- single file transpile
if string.match(path, ".-%.tl$") then
	local lines = transpile(path)
	for _, line in ipairs(lines) do
		table.insert(final_lines, line)
	end
	for n, l in ipairs(final_lines) do
		print(l)
	end
-- directory transpile
elseif string.match(path, ".-%/.-$") then
	-- included files
	print("2. Transpiling included .tl files...")
	for n, f in ipairs(config.include) do
		print("\t- " .. f)
		local lines = transpile(path .. f)
		for _, line in ipairs(lines) do
			table.insert(final_lines, line) 
		end
	end
	-- index file transpile
	print("3. Transpiling \"index.tl\" file.")
	local lines = transpile(path .. "/index.tl")
	for _, line in ipairs(lines) do
		table.insert(final_lines, line)
	end
	-- generate export file
	if not config.export then error("No export path found on tlconfig file.", 0) end
	local export_file = io.open(path .. config.export, "w")
	export_file:write(table.concat(final_lines, "\n"))
	export_file:close()
	print("Success.")
end