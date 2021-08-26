-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
local common = require "common"

local baseScreen = common.object:new()

function baseScreen:resize()
	for _, renderer in ipairs(self.renderers) do
		renderer:resize()
	end
end

function baseScreen:draw()
	for _, renderer in ipairs(self.renderers) do
		renderer:draw()
	end
end


function baseScreen:update(dt)
	for _, timer in pairs(self.timers) do
		timer:increment(dt)
	end
end

function baseScreen:touchpressed(x, y)
	for _, button in ipairs(self.touchButtons or {}) do
		if button:within(x, y) then
			button:pressed()
			break
		end
	end
end

return baseScreen
