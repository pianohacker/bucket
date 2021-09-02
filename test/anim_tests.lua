-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

local anim = require("anim")

notion("interval fires at or after given interval and automatically resets", function()
	local i = anim.interval:new(.8)
	i:increment(.2)
	check(i:firing()):is(false)
	i:increment(.3)
	check(i:firing()):is(false)
	i:increment(.2)
	check(i:firing()):is(false)
	i:increment(.25)
	check(i:firing()):is(true)

	i:increment(.8)
	check(i:firing()):is(true)
end)

notion("interval can be paused", function()
	-- Incrementing after pause
	local i = anim.interval:new(.8)
	i:pause()
	i:increment(.9)
	check(i:firing()):is(false)

	i:start()
	check(i:firing()):is(true)

	-- Incrementing before pause
	i = anim.interval:new(.8)
	i:increment(.9)
	i:pause()
	check(i:firing()):is(false)
end)

notion("interval can be stopped and resets when stopped", function()
	local i = anim.interval:new(.8)
	i:stop()
	i:increment(.9)
	check(i:firing()):is(false)

	i:start()
	check(i:firing()):is(false)

	i:increment(.8)
	check(i:firing()):is(true)
end)

notion("interval can be reset", function()
	local i = anim.interval:new(.8)
	i:increment(.9)

	i:reset()
	check(i:firing()):is(false)

	i:increment(.8)
	check(i:firing()):is(true)
end)

notion("interval can be resized", function()
	local i = anim.interval:new(.8)
	i:increment(.7)

	check(i:firing()):is(false)
	i:resize(.6)
	check(i:firing()):is(true)

	i:reset()
	check(i:firing()):is(false)
	i:increment(.9)
	check(i:firing()):is(true)
end)

notion("linearTransition interpolates between bounds", function()
	local i = anim.linearTransition:new(.5)
	check(i:range(0, 100)):is(0)

	i:increment(.1)
	check(i:range(0, 100)):is(20)

	i:increment(.15)
	check(i:range(0, 100)):is(50)

	i:increment(.25)
	check(i:range(0, 100)):is(100)
end)

notion("linearTransition clamps at end", function()
	local i = anim.linearTransition:new(.5)

	i:increment(.7)
	check(i:range(0, 100)):is(100)
end)

