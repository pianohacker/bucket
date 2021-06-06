-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local color = require("color")
local lu = require("luaunit.luaunit")

notion("cielchToRgb matches reference values", function()
	-- From http://www.brucelindbloom.com/index.html?ColorCalculator.html
	-- Ref White: D65
	-- Gamma: 2.2
	local refValues = {
		[{0, 0, 0}] = "#000000",
		[{0, 0, 180}] = "#000000",
		[{50, 0, 0}] = "#767676",
		[{50, 50, 0}] = "#AB6070",
		[{50, 50, 120}] = "#52823E",
		[{50, 50, 240}] = "#427BA7",
		[{75, 25, 0}] = "#D7ADB4",
	}

	for input, actual in pairs(refValues) do
		lu.assertEquals(
			color.cielchToRgb(unpack(input)),
			actual
		)
	end
end)
