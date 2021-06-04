-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
local common = lickRequire "common"
local graphics = lickRequire "graphics"

local baseScreen = lickRequire "screens/base"

local lossScreen = baseScreen:new()

function lossScreen:init(gameScreen)
	self.renderers = {
		graphics.LossRenderer:new(gameScreen),
	}
end

function lossScreen:update()
end

function lossScreen:keypressed(key)
	if key == 'space' or key == 'enter' then
		local gameScreen = lickRequire "screens/game"
		core.switchScreen(gameScreen:new())
	end
end

return lossScreen
