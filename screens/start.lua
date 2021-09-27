-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
local graphics = require "graphics"
local std = require "std"
local ui = require "ui"

local baseScreen = require "screens/base"

local startScreen = baseScreen:clone()

function startScreen:new()
	return self:extend({
		renderers = {
			graphics.StartRenderer:clone(),
		},
		keyInputMap = {
			space = 'START',
		},
	})
end

startScreen.layout = std.memoized(
	function() return ui.shape end,
	function(self, s)
		return {
			buttons = {
				ui.button:new(
					0,
					0,
					s.fullWidth,
					s.fullHeight,
					function() self:input('START') end
				),
			},
		}
	end
)

function startScreen:input(input)
	if input == 'START' then
		local gameScreen = require "screens/game"
		ui:switchScreen(gameScreen:new())
	end
end

return startScreen
