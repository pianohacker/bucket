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

	b:pressed(1, 1, 1)
	check(called):is(true)

	called = false
	b:pressed(1, 1, 3)
	check(called):is(false)
end)

notion("sliderButton emits one or more up events for each movement", function()
	local ups, downs = 0, 0

	local s = ui.sliderButton:new(
		100,
		100,
		100,
		500,
		5,
		function() ups = ups + 1 end,
		function() downs = downs + 1 end
	)

	s:pressed(1, 150, 150)
	s:moved(1, 160, 200)
	check(ups, downs):is(0, 0)

	s:moved(1, 160, 260)
	check(ups, downs):is(0, 1)

	s:moved(1, 160, 250)
	check(ups, downs):is(0, 1)

	s:moved(1, 160, 361)
	check(ups, downs):is(0, 2)

	s:moved(1, 160, 341)
	check(ups, downs):is(1, 2)

	s:moved(1, 160, 49)
	check(ups, downs):is(3, 2)

	s:released(1, 100, 190)
	s:moved(1, 300, 190)
	check(ups, downs):is(3, 2)
end)

notion("sliderButton ignores other presses", function()
	local ups, downs = 0, 0

	local s = ui.sliderButton:new(
		100,
		100,
		100,
		500,
		5,
		function() ups = ups + 1 end,
		function() downs = downs + 1 end
	)

	s:pressed(1, 150, 150)
	check(ups, downs):is(0, 0)

	s:moved(1, 150, 250)
	check(ups, downs):is(0, 1)

	s:pressed(2, 150, 150)
	s:moved(2, 150, 350)
	check(ups, downs):is(0, 1)

	s:released(2, 150, 350)
	s:moved(1, 160, 361)
	check(ups, downs):is(0, 2)
end)
