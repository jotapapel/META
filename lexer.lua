return {
	decorators =  {
		-- decorators
	},
	substitutions = {
		-- local variables
		["^let(%s+.-)$"] = "local%1",
		-- inline functions
		["%b()"] = function(a)
			a = string.format("%s,", string.match(a, "^%((.-)%)$")):gsub("(%b()):(.-),", "function%1%2 end,")
			return string.format("(%s)", a:match("(.-),%s*$"))
		end,
		-- inline if-else and ternary operator
		["^(.-)%s+if%s+(.-)%s+else%s+(.-)$"] = function(a, b, c)
			if a:match("^(.-)%s+=%s+(.-)$") then
				local d, e = a:match("^(.-)%s+=%s+(.-)$")
				return string.format("%s = (%s and %s) or %s", d, b, e, c)
			end
			return string.format("if %s then %s else %s end", b, a, c)
		end,
		-- negation
		["!([_%a][_%.%w]*)"] = "not(%1)",
		-- variable argument number
		["#..."] = "select(\"#\", ...)",
		-- shorthand operators
		["^(.-)%s+([%+%-%*%/%^])=%s+(.-)$"] = function(a, b, c)
			local d, e, f, g = {}, {}, "", ""
			for h in string.gmatch(string.format("%s,", a), "(.-),%s*") do
				table.insert(d, h)
			end
			for i in string.gmatch(string.format("%s,", c), "(.-),%s*") do
				table.insert(e, i)
			end
			for j = 1, #d do 
				f, g = string.format("%s%s, ", f, d[j]), e[j] and string.format("%s%s %s %s, ", g, d[j], b, e[j]) or g
			end
			return string.format("%s = %s", f:match("^(.-),%s+$"), g:match("^(.-),%s+$"))
		end
	},
	openings = {
		-- prototypes
		["^([_%a][_%.%w]*)%s+=%s+{(.-)}:$"] = function(a, b)
			b = #b > 0 and string.format("%s, ", b) or ""
			return string.format("%s = lang.prototype(%sfunction()", a, b)
		end,
		-- functions
		["^(.-%s+)(%(.-%)):$"] = "%1function%2",
		-- control structures
		["^if%s+(.-):$"] = "if %1 then",
		["^elseif%s+(.-):$"] = "elseif %1 then",
		["^else:$"] = "else",
		["^for%s+(.-):$"] = "for %1 do",
		["^while%s+(.-):$"] = "while %1 do",
		["^until%s+.-:$"] = "repeat",
		["^do:$"] = "do"
	},
	closings = {
		["^([_%a][_%.%w]*)%s+=%s+{(.-)}:$"] = "<end)>",
		["^if%s+(.-):$"] = "<end>",
		["^until%s+(.-):$"] = "<until> %s"
	}
}