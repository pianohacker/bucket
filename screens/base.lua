-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
local std = require "std"
local ui = require "ui"

local baseScreen = std.object:clone()

function baseScreen:init()
	self:layout()
end

function baseScreen:layout()
	return {}
end

function baseScreen:resize()
end

function baseScreen:draw()
	for _, renderer in ipairs(self.renderers) do
		renderer:draw()
	end
end

function baseScreen:update(dt)
	for _, timer in pairs(self.timers or {}) do
		timer:increment(dt)
	end
end

function baseScreen:pauseAll()
	for _, timer in pairs(self.timers or {}) do
		timer:pause()
	end
end

function baseScreen:startAll()
	for _, timer in pairs(self.timers or {}) do
		timer:start()
	end
end

function baseScreen:pressed(id, x, y)
	for _, button in pairs(self:layout().buttons or {}) do
		button:pressed(id, x, y)
	end
end

function baseScreen:moved(id, x, y)
	for _, button in pairs(self:layout().buttons or {}) do
		button:moved(id, x, y)
	end
end

function baseScreen:released(id, x, y)
	for _, button in pairs(self:layout().buttons or {}) do
		button:released(id, x, y)
	end
end

function baseScreen:keypressed(key, _, _)
	if self.keyInputMap[key] then
		self:input(self.keyInputMap[key])
	end
end

function baseScreen:newInputButton(x, y, width, height, input, label)
	x, y, width, height = ui.shape:relPctCoords(x, y, width, height)

	return ui.button:new(
		x,
		y,
		width,
		height,
		function()
			love.system.vibrate(.025)
			self:input(input)
		end
	):extend({
		label = label,
	})
end

function baseScreen:newInputSliderButton(x, y, width, height, steps, upInput, downInput)
	x, y, width, height = ui.shape:relPctCoords(x, y, width, height)

	return ui.sliderButton:new(
		x,
		y,
		width,
		height,
		steps,
		function()
			love.system.vibrate(.005)
			self:input(upInput)
		end,
		function()
			love.system.vibrate(.005)
			self:input(downInput)
		end
	)
end

return baseScreen
