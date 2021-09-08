-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.

module("anim", package.seeall)

local std = require("std")

interval = std.object:extend({
	elapsed = 0,
	new = function(self, length)
		return self:extend({ length = length })
	end,

	resize = function(self, length)
		self.length = length
	end,

	increment = function(self, dt)
		if self.stopped then return false end

		self.elapsed = self.elapsed + dt
	end,

	firing = function(self)
		if self.paused or self.stopped then return false end

		if self.elapsed >= self.length then
			self.elapsed = 0
			return true
		end

		return false
	end,

	pause = function(self)
		self.paused = true
	end,

	stop = function(self)
		self.stopped = true
	end,

	start = function(self)
		self.stopped = false
		self.paused = false
	end,

	reset = function(self)
		self.elapsed = 0
	end,
})

linearTransition = std.object:extend({
	elapsed = 0,
	new = function(self, length)
		return self:extend({ length = length })
	end,

	increment = function(self, dt)
		self.elapsed = math.min(self.elapsed + dt, self.length)
	end,

	range = function(self, min, max)
		return min + (max - min) * self.elapsed / self.length
	end,
})
