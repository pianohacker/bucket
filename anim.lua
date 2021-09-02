-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

module("anim", package.seeall)

local std = require("std")

interval = std.object:new()

function interval:init(length)
	self.length = length
	self.elapsed = 0
end

function interval:resize(length)
	self.length = length
end

function interval:increment(dt)
	if self.stopped then return false end

	self.elapsed = self.elapsed + dt
end

function interval:firing()
	if self.paused or self.stopped then return false end

	if self.elapsed >= self.length then
		self.elapsed = 0
		return true
	end

	return false
end

function interval:pause()
	self.paused = true
end

function interval:stop()
	self.stopped = true
end

function interval:start()
	self.stopped = false
	self.paused = false
end

function interval:reset()
	self.elapsed = 0
end

linearTransition = std.object:new()

function linearTransition:init(length)
	self.length = length
	self.elapsed = 0
end

function linearTransition:increment(dt)
	self.elapsed = math.min(self.elapsed + dt, self.length)
end

function linearTransition:range(min, max)
	return min + (max - min) * self.elapsed / self.length
end
