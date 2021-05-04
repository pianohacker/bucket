local common = require("test.common")

notion("dedent works correctly", function()
	check(common.dedent([[
		abc
		def
			ced
	]])).is("abc\ndef\n\tced")
	check(common.dedent([[
			abc
		def
			ced
	]])).is("\tabc\ndef\n\tced")
end)

notion("grid works correctly for a single grid", function()
	local g = common.grid [[
		_x
		xx
		x_
		x_
	]]

	check(g[1]).shallowMatches({false, true, true, true})
	check(g[2]).shallowMatches({true, true, false, false})
end)

notion("grid works correctly for multiple grids", function()
	local g1, g2 = common.grid [[
		_x
		_x
		x_
		xx
		x_xx
		___x
	]]

	check(g1[1]).shallowMatches({false, false, true, true})
	check(g1[2]).shallowMatches({true, true, false, true})

	check(g2[1]).shallowMatches({true, false})
	check(g2[2]).shallowMatches({false, false})
	check(g2[3]).shallowMatches({true, false})
	check(g2[4]).shallowMatches({true, true})
end)
