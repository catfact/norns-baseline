-- baseline norns performance test
-- 
-- runs stress tests
-- test 1: all softcut voices at 8x, R+W
-- test 2: many sinewaves in supercollider
-- test 3: both (optional)
--
-- performance results are saved
-- in ~/dust/data/baseline

engine.name = 'BaselineSines'

------------------------------------------
--- vars

---- constants
nsamples = 500
sample_period = 0.25
nsines = 360

run_softcut = true
run_sines = false
run_both = false

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

function git_head(loc)
    local res = util.os_capture('cd '..loc..' && git log --pretty=format:%h\\ %d\\ %s -n 1')
    return res
end

function get_cpu_hz() 
    local f = io.open('/sys/devices/system/cpu/cpu0/cpufreq/scaling_cur_freq')
    local res = f:read("*a")
    f:close()
    return res
end

function capture(name)
    -- clear the saved xrun count
    local cpu_hz_start = get_cpu_hz()
    local cpu_hz_mid = nil
    _ = _norns.audio_get_xrun_count()
    cpu_history = {}
    xruns_history = {}
    local n2 = nsamples/2
    for i=1,nsamples do
        table.insert(cpu_history, _norns.audio_get_cpu_load())
        table.insert(xrun_history, _norns.audio_get_xrun_count())
        if i==n2 then 
            cpu_hz_mid = get_cpu_hz()
        end
        clock.sleep(sample_period)
    end
    
    local datestr = os.date('%Y%m%d_%H%M%S', os.time())
    local outfile = _path.data..'baseline/data_'..name..'_'..datestr..'.csv'
    local f=io.open(outfile,'w+')
    f:write('cpu,\txruns,\t\n')
    for i,v in ipairs(cpu_history) do
        f:write(tostring(v)..',\t'..tostring(xrun_history[i])..',\t\n')
    end
    f:close()
    local cpu_hz_end = get_cpu_hz()
    outfile = _path.data..'baseline/stats_'..name.."_"..datestr..'.toml'
    f=io.open(outfile,'w+')
    f:write('[meta]\n')
    f:write('norns_version = "'..git_head('~/norns')..'"\n')
    f:write('softcut_version = "'..git_head('~/norns/crone/softcut')..'"\n')
    f:write('N = '..#cpu_history..'\n')
    f:write('period = '..sample_period..'\n')
    f:write('\n\n')
    
    f:write('[speed]\n')
    f:write('"cpu_hz_start" = '..cpu_hz_start)
    f:write('"cpu_hz_mid" = '..cpu_hz_mid)
    f:write('"cpu_hz_end" = '..cpu_hz_end)
    f:write('\n\n')

    local write_stats = function(data) 
        local statsk = {'min','max','mean','median','q1','q3'}
        local st = stats(data)
        for i,k in ipairs(statsk) do
            f:write(k..' = '..st[k]..'\n')
        end
    end
    f:write('[load]\n')
    write_stats(cpu_history)
    f:write('\n\n')

    f:write('[xruns]\n')
    write_stats(xrun_history)

    f:close()
end

function softcut_stress(dur)
    local regions={
        {1,1,80},
        {1,82,161},
        {1,163,243},
        {2,1,80},
        {2,82,161},
        {2,163,243},
    }
    audio.level_cut(1)
    audio.level_adc_cut(1)
    audio.level_eng_cut(1)
    audio.level_tape_cut(1)
    for i=1,6 do
        softcut.enable(i,1)
    
        softcut.level_input_cut(1,i,0.5)
        softcut.level_input_cut(2,i,0.5)
    
        softcut.buffer(i,regions[i][1])
        softcut.level(i,1.0)
        softcut.pan(i,0)
        softcut.loop(i,1)
        softcut.loop_start(i,regions[i][2])
        softcut.loop_end(i,regions[i][3])
    
        softcut.level_slew_time(i,0.2)
        softcut.rate_slew_time(i,0.0)
        softcut.recpre_slew_time(i,0.1)
        softcut.fade_time(i,0.2)
    
        softcut.rec_level(i,0.5)
        softcut.pre_level(i,0.5)
        softcut.phase_quant(i,0.025)
    
        softcut.post_filter_dry(i,0.0)
        softcut.post_filter_lp(i,1.0)
        softcut.post_filter_rq(i,1.0)
        softcut.post_filter_fc(i,20100)
    
        softcut.pre_filter_dry(i,1.0)
        softcut.pre_filter_lp(i,1.0)
        softcut.pre_filter_rq(i,1.0)
        softcut.pre_filter_fc(i,20100)
    
        softcut.position(i,regions[i][2])
        softcut.play(i,1)
        softcut.rec(i,1)
        softcut.rate(i,8)

        clock.sleep(0.1)

        -- add a really slow rate slew down
        softcut.rate_slew_time(i, dur)
        softcut.rate(i, 7.5)
    end
end

function sines_stress()
    local randhz = function()
        return 55.0 * math.pow(2.0, math.random()*4)
    end
    for i=1,nsines do
        engine.newsine(0.02, randhz(), math.random()-0.5)
        clock.sleep(0.01)
    end
end

function main() 

    if run_softcut then
        say('resetting softcut...')
        softcut.reset()
        clock.sleep(1)
        say("playing softcut...")
        softcut_stress(nsamples * sample_period * 0.5)
        clock.sleep(1)
        say('capturing CPU (softcut)...')
        capture('softcut')
        say('done.')
    end

    if run_sines then
        say('resetting softcut...')
        softcut.reset()
        clock.sleep(1)
        say('playing sines...')
        sines_stress()
        say('capturing CPU (sines)...')
        clock.sleep(1)
        capture('sines')
        say('done.')
        engine.clear()
        clock.sleep(1)
    end

    if run_both then
        say('playing sines again...')
        sines_stress()
        say('capturing CPU (both)...')
        clock.sleep(0.01)
        capture('both')
        say('done.')
        engine.clear()
        clock.sleep(0.1)
    end
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
    audio.rev_on()
    audio.comp_on()
    main_clock = clock.run(main)
end

cleanup = function()
    clock.cancel(main_clock)
end