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

	asStopped = function(self)
		self:stop()

		return self
	end,

	resize = function(self, length)
		self.length = length
	end,

	increment = function(self, dt)
		if self.paused then return false end

		self.elapsed = self.elapsed + dt
	end,

	firing = function(self)
		if self.paused then return false end

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
		self:pause()
		self:reset()
	end,

	start = function(self)
		self.paused = false
	end,

	reset = function(self)
		self.elapsed = 0
	end,

	restart = function(self)
		self:start()
		self:reset()
	end,

	finished = function(self)
		return self.elapsed > self.length
	end,
})

linearTransition = interval:extend({
	range = function(self, min, max)
		if self:finished() then return max end

		return min + (max - min) * self.elapsed / self.length
	end,
})

sharpInOutTransition = interval:extend({
	new = function(self, inLength, outLength)
		return self:extend({
			inLength = inLength,
			outLength = outLength,
			length = inLength + outLength,
		})
	end,

	range = function(self, min, max)
		local t = 0
		if self.elapsed <= self.inLength then
			t = self.elapsed / self.inLength
		elseif self.elapsed <= self.length then
			t = (1 - (self.elapsed - self.inLength) / self.outLength)
		end

		return min + (max - min) * t * t
	end,
})
