string.mask=function(a,b)return b:gsub("%$",a)end

cheese = {}

cheese.array = function(a)
	return a:gsub("%b[]", function(b)
		b = b:match("^%[(.-)%]$")
		return cheese.array(b):mask("$,"):gsub("(.-):%s+(.-),%s*", function(c, d)
			if tonumber(c) or c:match("^(<b%x+/>)$") then c = c:mask("[$]") end
			return c .." = " .. d .. ", "
		end):match("^(.-),%s*$"):mask("{$}")
	end)
end

cheese.patch = function(a, b, c, d)
	local d, e, f = d or "$", {}, 0
	a = a:gsub(b, function(g)
		local h = string.format("%s%02i", tostring(e):sub(-5), f)
		e[h], f = g:mask(d), f + 1
		return h:mask(c)
	end)
	e.a, e.b = c, f
	return a, e
end

cheese.reform = function(a, ...)
	local b = {...}
	local c, d = table.remove(b), 0
	while c do
		if d < c.b then
			local e = string.format("%s%02i", tostring(c):sub(-5), d)
			local f, g = a:match("^(.-)" .. e:mask(c.a) .. "(.-)$")
			d, a = d + 1, f .. c[e] .. g
		else
			c, d = table.remove(b), 0
		end
	end
	return a
end

local patterns = {["if"] = " $ then", ["elseif"] = " $ then", ["else"] = "$", ["while"] = " $ do", ["for"] = " $ do"}
cheese.parse = function(a, b)
	local c, d = a:match("^(.-):%s+.-$") or a:match("^(.-):%s*$") or "", a:match("^.-:%s+(.-)$")
	local e = function() if d then d = cheese.parse(d):mask(" $ end") else d, b.a, b.b[b.a] = "", b.a + 1, "end" end return d end
	-- control structures
	local f, g = c:match("^(%l+)%s+.-$") or c:match("^(%l+)$"), c:match("^%l+%s+(.-)$") or ""
	if patterns[f] then
		return f .. g:mask(patterns[f]) .. e(), b
	end
	-- prototypes
	f, g = c:match("^def%s+([_%a][%._%w]+){(.-)}$")
	if f and g then
		g, b.a, b.b[b.a] = string.mask(#g > 0 and g or "nil", "$, "), b.a + 1, "end)"
		return string.format("%s = prototype(%sfunction()", f, g), b
	end
	-- functions
	f, g = c:match("^(.-)def%(.-%)$") or c:match("^(.-)%(.-%)$"), c:match("^.-def(%(.-%))$") or c:match("^.-(%(.-%))$")
	if f and g then
		local h = f:match("^def%s+([_%a][_%w%.]+)$")
		if f:match("^([_%a][_%w%.]+)$") and b.b[b.a - 1] == "end)" then f, g = f:mask("$ = "), "(self" .. (#g > 2 and g:match("^%((.-)$"):mask(", $") or ")") end
		return string.mask(h or f, h and "function $" or "$function") .. g .. e(), b
	end
	return a, b
end

cheese.lines = function(a)
	local b, c, d = io.open(a, "r"), {}, 0 
	if b then
		for z in io.lines(a) do table.insert(c, z) end
		b:close()
	end
	return function()
		while d < #c do
			d = d + 1
			return #c[d]:match("^(%s*).-$"), c[d]:match("^%s*(.-)%s*$")
		end
	end
end

cheese.file = function(a)
	local b, c, d = {}, {a = 0, b = string.char(9)}, {a = -1, b = {}}
	for e, f in cheese.lines(a) do
		-- insert placeholders
		local fa, fb, fc, fd
		f, fa = cheese.patch(f, "\\.", "<a$/>")
		f, fb = cheese.patch(f, "%b\"\"", "<b$/>")
		f, fc = cheese.patch(f, "([_%a][_%w%.]+%b[])", "<c$/>")
		f, fd = cheese.patch(f, "\'(.-)$", "<d$/>", "--$")
		-- generate closings
		if e <= d.a then
			local z = f:match("^elseif%s+.-:.-$") or f:match("^else:.-$")
			c.a, d.a, d.b[d.a] = c.a - (z and 0 or 1), d.a - 1, ""
			if not z then table.insert(b, c.b:rep(c.a) .. d.b[d.a]) end
		end
		-- parse the line
		local g, h = cheese.array(f:match("^(.-)<d%x+/>$") or f), f:match("(<d%x+/>)$") or ""
		g, d = cheese.parse(g, d)
		-- repatch the line and generate the right indentation
		local i = g:gsub("%b{}", "<a/>"):gsub("%b()", "<b/>"):gsub("function<b/>.-end", "<c/>"):gsub("function%s+.-<b/>.-end", "<c/>")
		if i:match("^until.-$") or i:match("^end.-$") or i:match("^elseif%s+.-%s+then$") or i:match("^else$") or i:match("^%s*}%s*.-$") then c.a = c.a - 1 end
		if #f > 0 then table.insert(b, c.b:rep(c.a) .. g) end
		if i:match("^while%s+.-%s+do$") or i:match("^repeat$") or i:match("^.-%s*function<b/>$") or i:match("^.-%s*function%s+.-$") or i:match("^.-%s+then$") or i:match("^else$") or (i:match("^.-do$") and not i:match("^.-end.-$")) or i:match("^.-%s*{%s*$") then c.a = c.a + 1 end
	end
	while d.a > -1 do
		c.a, d.a, d.b[d.a] = c.a - 1, d.a - 1, ""
		table.insert(b, c.b:rep(c.a) .. d.b[d.a])
	end
	return b
end

local lines = cheese.file("test.gs")
print(table.concat(lines, "\n"))
