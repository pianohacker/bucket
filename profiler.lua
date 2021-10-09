--
-- use with luajit 2.1 profiler
-- klua.log functions not included! make your own :)
-- to be used with love2d 

local log = {}
function log.warning(...)
	print('[WARN]', ...)
end
function log.info(...)
	print('[INFO]', ...)
end

local G = love.graphics

local profile
local vmdef 

if jit.version_num >= 20100 then
    profile = require "jit.profile"
    vmdef   = require "jit.vmdef"
else
    log.warning('Profiler unavailable in %s. (2.1 or later required)', jit.version)
end

local format  = string.format
local sort    = table.sort
local math    = math
local floor   = math.floor

prof = {}

prof.running = false
prof.flag_l2_shown = true
prof.flag_l2_levels = 3
prof.profiler_fmt = "Fi10"
prof.min_percent = 1
prof.l1_stack_fmt = "F"
prof.l2_stack_fmt = "l <"
prof.counts = {}  -- double index
prof.top_str = nil

local total_samples = 0

------------------------------------------------------------
local function prof_cb(thread,samples,vmmode)
    local c = prof.counts
    total_samples = total_samples + samples
    local l1_stack = profile.dumpstack(thread, prof.l1_stack_fmt, 1)
    local l2_stack = profile.dumpstack(thread, prof.l2_stack_fmt, 5)

    l1_stack = l1_stack:gsub("%[builtin#(%d+)%]", function(x) return vmdef.ffnames[tonumber(x)] end)
    l2_stack = l2_stack:gsub("%[builtin#(%d+)%]", function(x) return vmdef.ffnames[tonumber(x)] end)
    
    if not c[l1_stack] then
        local vl1 = {key=l1_stack, count=0, callers={}}  -- double index
        c[l1_stack] = vl1
        c[#c+1] = vl1
    end
    c[l1_stack].count = c[l1_stack].count + samples

    if not c[l1_stack].callers[l2_stack] then
        local vl2 = {key=l2_stack, count=0}
        local c2 = c[l1_stack].callers
        c2[l2_stack] = vl2
        c2[#c2+1] = vl2
    end
    c[l1_stack].callers[l2_stack].count = c[l1_stack].callers[l2_stack].count + samples        
end

function prof.format_result()
    local c = prof.counts
    local out = {}
    
    -- sort l1
    sort(c, function(a,b) return a.count > b.count end)

    -- sort l2
    for i,v in ipairs(c) do
        sort(v.callers, function(a,b) return a.count > b.count end)
    end

    -- format
    for i=1,#c do
        local vl1 = c[i]        
        local pct = floor(vl1.count * 100 / total_samples + 0.5)
        if pct < prof.min_percent then break end
        table.insert(out, format("%2d%% %s", pct, vl1.key))
        local c2 = vl1.callers

        if prof.flag_l2_shown then 
            for j=1,#c2 do
                if j > prof.flag_l2_levels then break end
                local vl2 = c2[j]
                table.insert(out, format("    %4d %s", vl2.count, vl2.key))            
            end
        end
    end

    return table.concat(out,'\n')
end

function prof.draw(w,h,font)
    if prof.flag_dirty then
        prof.top_str = prof.format_result()    
        prof.flag_dirty = nil
    end    
	print(prof.top_str)
    local top = prof.top_str or "Profiler report is empty."
    G.setColor(30,30,30, 255)
    G.rectangle('fill', w/2+20, 20, w/2-40, h-40)
    G.setColor(243,236,207, 255)
    if font then 
        G.setFont(font)
    end
    G.print(top,w/2 + 30, 30)
end

function prof.start()
    if not profile then
        log.warning("LuaJIT profiler unavailable. (LuaJIT 2.0?)")
        return
    end
    if prof.running then
        log.info("LuaJIT profiler already running")
        return
    end

    log.info("LuaJIT profiler STARTED")
    total_samples = 0
    prof.counts = {}
    profile.start(prof.profiler_fmt, prof_cb)            
    prof.running = true
end

function prof.stop()
    if not profile then
        log.warning("LuaJIT profiler unavailable. (LuaJIT 2.0?)")
        return
    end
    if not prof.running then
        log.info("LuaJIT profiler not running")
        return
    end
    log.info("LuaJIT profiler STOPPED")
    profile.stop()
    prof.running = false
    prof.flag_dirty = true
end


------------------------------------------------------------
return prof

