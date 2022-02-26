-- baseline norns performance test
-- 
-- runs stress tests on supercollider/softcut

engine.name = 'BaselineSines'

------------------------------------------
--- vars

---- constants
nsamples = 10
sample_period = 0.25

nsines = 300

---- state
cpu_history = {}
xrun_history = {}
msg = ''
main_clock = nil

------------------------------------------
--- script functions


local say = function(str)
    print(str)
    msg = str
    redraw()
end

-- apply linear interpolation to table values at (float) index
local interp = function(t, x)
    local ix = math.floor(x)
    local c = x - ix
    local a = t[ix]
    local b = t[ix+1]
    return a + c*(b-a)
end

-- given an array of numbers,
-- return a table with some basic statistical descriptors
local stats = function(arr)
    y = {}
    local n = #arr
    local min = math.huge
    local max = -math.huge
    local mean = 0
    for i,x in ipairs(arr) do
        if x < min then min = x end
        if x > max then max = x end
        mean = mean + x
    end
    mean = mean / n
    y['min'] = min
    y['max'] = max
    y['mean'] = mean
    table.sort(arr)
    local i2 = 1 + (n-1)/2
    local i1 = 1 + (n-1)/4
    local i3 = n - i1 + 1
    print('n='..n..'; i1='..i1..'; i2='..i2..'; i3='..i3)
    y['q1'] = interp(arr, i1)
    y['median'] = interp(arr, i2)
    y['q3'] = interp(arr, i3)
    return y 
end


function capture(name)
    cpu_history = {}
    xruns_history = {}
    for i=1,nsamples do
        table.insert(cpu_history, _norns.audio_get_cpu_load())
        table.insert(xrun_history, _norns.audio_get_xrun_count())
        clock.sleep(sample_period)
    end
    
    local datestr = os.date('_%Y%m%d_%H%M%S', os.time())
    local outfile = _path.data..'baseline/data_'..name..datestr..'.csv'
    local f=io.open(outfile,'w+')
    f:write('cpu,\txruns,\t\n')
    for i,v in ipairs(cpu_history) do
        f:write(tostring(v)..',\t'..tostring(xrun_history[i])..',\t\n')
    end
    f:close()

    outfile = _path.data..'baseline/stats_'..name..datestr..'.csv'
    f=io.open(outfile,'w+')
    f:write('[meta]\n')
    f:write('N = '..#cpu_history..'\n')
    f:write('period = '..sample_period..'\n')
    f:write('\n\n')
    f:write('[cpu]\n')
    local statsk = {'min','max','mean','median','q1','q3'}
    local write_stats = function() end
    for i,v in ipairs(stats(cpu_history)) do
        f:write(k..' = '..v..'\n')
    end
    f:write('\n\n')
    f:write('[xruns]\n')
    for k,v in pairs(stats(cpu_history)) do
        f:write(k..' = '..v..'\n')
    end
    f:close()
end



function main() 
    say('playing sines...')
    local randhz = function()
        return 55.0 * math.pow(2.0, math.random()*4)
    end
    for i=1,nsines do
        engine.newsine(0.02, randhz(), math.random()-0.5)
        clock.sleep(0.01)
    end

    say('capturing CPU (sines)...')
    clock.sleep(0.01)
    capture('sines')
    say('done.')
    clock.sleep(0.01)
    engine.clear()
    -- test softcut
    -- TODO
end

--------------------
---- norns API functions

redraw = function()
    screen.clear()
    screen.level(10)
    screen.move(10, 10)
    screen.text(msg)
    screen.update()
end

init = function()
    main_clock = clock.run(main)
end

cleanup = function()
    clock.cancel(main_clock)
    -- FIXME: need to do something like close file pointers etc?
    -- (currently, breaks if re-run before finish?)
end