-- lick.lua
--
-- simple LIVECODING environment with löve, overwrites love.run, pressing all errors to the terminal/console
--
-- Modified from upstream (https://github.com/usysrc/LICK/blob/master/lick.lua).
--
-- FIXME: LICK does not currently have a license, add info when
-- https://github.com/usysrc/LICK/issues/8 is resolved.

local lick = {}
lick.files = {"main.lua"}
lick.debug = false
lick.reset = false
lick.clearFlag = false
lick.sleepTime = love.graphics.newCanvas and 0.001 or 1

local last_modified = {}

local function handle(err)
  return "ERROR: " .. err .. "\nTRACEBACK: " .. debug.traceback()
end

-- Initialization
local function load()
  last_modified = {}
end

local function update(dt)
	local changed = nil
	for _, filename in ipairs(lick.files) do
		local info = love.filesystem.getInfo(filename)
		local old_last_modified = last_modified[filename]
		if info and (old_last_modified or 0) < info.modtime then
			last_modified[filename] = info.modtime
			if old_last_modified then
				changed = filename
				break
			end
		end
	end

    if changed then
        success, chunk = pcall(love.filesystem.load, changed)
        if not success then
            print(tostring(chunk))
            lick.debugoutput = chunk .. "\n"
        end
        ok,err = xpcall(chunk, handle)

        if not ok then 
            print("CHUNK ERROR: " .. changed .. ": "..tostring(err))
            if lick.debugoutput then
                lick.debugoutput = (lick.debugoutput .."CHUNK ERROR: " .. changed .. ": ".. err .. "\n" )
            else 
                lick.debugoutput =  err .. "\n" 
            end 
        else
            print("CHUNK LOADED: " .. changed .. "\n")
            lick.debugoutput = nil
        end

        if lick.reset then
            loadok, err = xpcall(function()
				love.load(love.arg.parseGameArguments(arg), arg)
			end, handle)
            if not loadok then
                print("RESET ERROR: "..tostring(err))
                if lick.debugoutput then
                    lick.debugoutput = (lick.debugoutput .."RESET ERROR: ".. err .. "\n" ) 
                else
                    lick.debugoutput =  err .. "\n"
                end
            end
        end
    end

    updateok, err = pcall(love.update,dt)
    if not updateok and not updateok_old then 
        print("UPDATE ERROR: "..tostring(err))
        if lick.debugoutput then
            lick.debugoutput = (lick.debugoutput .."UPDATE ERROR: ".. err .. "\n" ) 
        else
            lick.debugoutput =  err .. "\n"
        end
  end
  
  updateok_old = not updateok
end

local function draw()
    drawok, err = xpcall(love.draw, handle)
    if not drawok and not drawok_old then 
        print(tostring(err))
        if lick.debugoutput then
            lick.debugoutput = (lick.debugoutput .. err .. "\n" ) 
        else
            lick.debugoutput =  err .. "\n"
        end 
    end

    if lick.debug and lick.debugoutput then 
        love.graphics.setColor(255,255,255,120)
        love.graphics.printf(lick.debugoutput, (love.graphics.getWidth()/2)+50, 0, 400, "right")
    end
    drawok_old = not drawok
end


function love.run()
	if love.load then love.load(love.arg.parseGameArguments(arg), arg) end

    math.randomseed(os.time())
    math.random() math.random()
    load()

    local dt = 0

    -- Main loop time.
    while true do
        -- Process events.
        if love.event then
            love.event.pump()
            for e,a,b,c,d in love.event.poll() do
            if e == "quit" then
                if not love.quit or not love.quit() then
                    if love.audio then
                        love.audio.stop()
                    end
                return
                end
            end

            love.handlers[e](a,b,c,d)
        end
    end

    -- Update dt, as we'll be passing it to update
    if love.timer then
        love.timer.step()
        dt = love.timer.getDelta()
    end

    -- Call update and draw
    if update then update(dt) end -- will pass 0 if love.timer is disabled
    if love.graphics then
        love.graphics.clear()
        if draw then draw() end
    end

    if love.timer then love.timer.sleep(lick.sleepTime) end
    if love.graphics then love.graphics.present() end
  end
end

return lick
