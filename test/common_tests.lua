-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

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

notion("grid works correctly", function()
	local gridStr = [[
	     █▀▀██▀█
	  ▄▄▄█▄█▀▀▀█▄▄▄
	  █   ▄ ▄  ▄▄▀█
	  ██ ▀█ ▄██▀█ █
	  █▄▄▄   ▄ ▄█▄█
	     █ █ █ █
	     ▀▀▀▀▀▀▀
	]]
	local upper, lower = common.grid(gridStr)
	check(#upper).is(20)
	check(#upper[1]).is(3)
	check(#lower).is(5)
	check(#lower[1]).is(5)

	check(common.gridRepr(upper, lower)).is(common.dedent(gridStr))
end)
