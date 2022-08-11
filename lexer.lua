return {
  openings = {
		["([_%a][_%.%w]*)%s+=%s+{(.-)}:$"] = function(a, b)
			b = #b > 0 and string.format("%s, ", b) or ""
			return string.format("%s = lang.prototype(%sfunction()", a, b)
		end,
		["(.-%s+)(%(.-%)):$"] = "%1function%2",
    ["^if%s+(.-):$"] = "if %1 then",
    ["^elseif%s+(.-):$"] = "elseif %1 then",
    ["^else:$"] = "else",
		["^for%s+(.-):$"] = "for %1 do",
		["^while%s+(.-):$"] = "while %1 do",
		["^until%s+.-:$"] = "repeat",
		["^do:$"] = "do",
  },
  closings = {
    ["([_%a][_%.%w]*)%s+=%s+{(.-)}:$"] = "<end)>",
		["^until%s+(.-):$"] = "<until> %s"
  },
  substitutions = {
    ["let%s+(.-)$"] = "local %1",
    ["!([_%a][_%.%w]*)"] = "not(%1)",
		["%$([_%a][_%.%w]*)"] = "tostring(%1)",
		["#%.%.%."] = "select(\"#\", ...)",
		["([_%a][%.%_%w]*)([%+%-].)"] = function(a, b)
			if string.sub(b, 1, 1) == string.sub(b, -1) then
				return string.format("%s = %s %s 1", a, a, string.sub(b, 1, 1))
			end
		end
  },
	inline = {
		["^(<INLINE_FUNCTION.->)(.-)$"] = "%1 %2 end",
		["^(.-)%s+if%s+(.-)%s+else%s+(.-)$"] = "%2 and %1 or %3"
	},
	decorators = {
		["abstract"] = 
	}
}