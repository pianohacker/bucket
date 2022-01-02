-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
local anim = require "anim"
local graphics = require "graphics"

local baseScreen = require "screens/base"

local pauseScreen = baseScreen:clone()

function pauseScreen:new()
	return self:extend(function(o)
		o.timers = {
			fadeIn = anim.linearTransition:new(0.3),
		}

		o.renderers = {
			graphics.PauseRenderer:new(
				function() return o.timers.fadeIn:range(0, 1) end
			),
		}

		o.keyInputMap = {
			space = 'CONTINUE',
		}
	end)
end

pauseScreen.layout = std.memoized(
	function() return ui.shape end,
	function(self, s)
		return {
			buttons = {
				ui.button:new(
					0,
					0,
					s.fullWidth,
					s.fullHeight,
					function() self:input('CONTINUE') end
				),
			},
		}
	end
)

function pauseScreen:input(input)
	if input == 'CONTINUE' then
		ui:removeScreen(pauseScreen)
	end
end

return pauseScreen
