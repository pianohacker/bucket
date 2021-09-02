-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
local common = require "common"

local baseScreen = common.object:new()

function baseScreen:init()
	self:layout()
end

function baseScreen:layout()
end

function baseScreen:resize()
	self:layout()

	for _, renderer in ipairs(self.renderers) do
		renderer:resize(width, height)
	end
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

function baseScreen:mousepressed(x, y)
	for _, button in pairs(self.buttons or {}) do
		if button:within(x, y) then
			button:pressed()
			break
		end
	end
end

function baseScreen:keypressed(key, _, _)
	if self.keyInputMap[key] then
		self:input(self.keyInputMap[key])
	end
end

function baseScreen:newInputButton(x, y, width, height, input)
	x, y, width, height = ui.shape:relPctCoords(x, y, width, height)

	return common.button:new(x, y, width, height, function() self:input(input) end)
end

return baseScreen
