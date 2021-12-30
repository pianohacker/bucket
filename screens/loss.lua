-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
local anim = require "anim"
local graphics = require "graphics"

local baseScreen = require "screens/base"

local lossScreen = baseScreen:clone()

function lossScreen:new(gameScreen)
	return self:extend(function(o)
		o.timers = {
			fadeIn = anim.linearTransition:new(1),
		}

		o.renderers = {
			graphics.LossRenderer:new(
				gameScreen,
				function() return o.timers.fadeIn:range(0, 1) end
			),
		}

		o.keyInputMap = {
			space = 'RESTART',
		}
	end)
end

lossScreen.layout = std.memoized(
	function() return ui.shape end,
	function(self, s)
		return {
			buttons = {
				ui.button:new(
					0,
					0,
					s.fullWidth,
					s.fullHeight,
					function() self:input('RESTART') end
				),
			},
		}
	end
)

function lossScreen:input(input)
	if input == 'RESTART' then
		local gameScreen = require "screens/game"
		ui:switchScreen(gameScreen:new())
	end
end

return lossScreen
