-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local ui = require("ui")

notion("button positioned from top-left correctly checks touches", function()
	local b = ui.button:new(25, 25, 70, 50)

	-- Center
	check(b:within(50, 50)):is(true)

	-- Horizontal edges
	check(b:within(24, 50)):is(false)
	check(b:within(25, 50)):is(true)
	check(b:within(94, 50)):is(true)
	check(b:within(95, 50)):is(false)

	-- Vertical edges
	check(b:within(50, 24)):is(false)
	check(b:within(50, 25)):is(true)
	check(b:within(50, 74)):is(true)
	check(b:within(50, 75)):is(false)
end)

notion("button calls its handler when pressed", function()
	local called = false
	local b = ui.button:new(1, 1, 1, 1, function() called = true end)

	b:pressed()
	check(called):is(true)
end)
