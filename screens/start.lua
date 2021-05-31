-- Copyright (c) Jesse Weaver, 2021
--
-- This Source Code Form is subject to the terms of the Mozilla Public
-- License, v. 2.0. If a copy of the MPL was not distributed with this
-- file, You can obtain one at https://mozilla.org/MPL/2.0/.
--
local common = lickRequire "common"
local graphics = lickRequire "graphics"

local gameScreen = lickRequire "screens/game"

local startScreen = common.object:new()

function startScreen:init()
	self.renderers = {
		graphics.StartRenderer:new(),
	}
end

function startScreen:update()
end

function startScreen:keypressed(key)
	if key == 'space' or key == 'enter' then
		core.switchScreen(gameScreen)
	end
end

return startScreen
