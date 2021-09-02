-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
local anim = require "anim"
local graphics = require "graphics"

local baseScreen = require "screens/base"

local lossScreen = baseScreen:new()

function lossScreen:init(gameScreen)
	self.timers = {
		fadeIn = anim.linearTransition:new(1)
	}

	self.renderers = {
		graphics.LossRenderer:new(
			gameScreen,
			function() return self.timers.fadeIn:range(0, 1) end
		),
	}
end

function lossScreen:update(dt)
	baseScreen.update(self, dt)
end

function lossScreen:keypressed(key)
	if key == 'space' or key == 'enter' then
		local gameScreen = require "screens/game"
		ui:switchScreen(gameScreen:new())
	end
end

return lossScreen
