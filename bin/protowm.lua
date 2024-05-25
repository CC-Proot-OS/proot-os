local loop = require("taskmaster")()
term.clear()
local wm = {}
_G.wm = wm
loop:setEventBlacklist { "key", "key_up", "char", "paste", "mouse_click", "mouse_up", "mouse_scroll", "mouse_drag" }
local function panic(ae)
    term.setBackgroundColor(32768)
    term.setTextColor(16384)
    term.setCursorBlink(false)
    local p, q = term.getCursorPos()
    p = 1; local af, ag = term.getSize()
    ae = "panic: " .. (ae or "unknown")
    for ah in ae:gmatch "%S+" do
        if p + #ah >= af then
            p, q = 1, q + 1; if q > ag then
                term.scroll(1)
                q = q - 1
            end
        end; term.setCursorPos(p, q)
        if p == 1 then term.clearLine() end; term.write(ah .. " ")
        p = p + #ah + 1
    end; p, q = 1, q + 1; if q > ag then
        term.scroll(1)
        q = q - 1
    end; if debug then
        local ai = debug.traceback(nil, 2)
        for aj in ai:gmatch "[^\n]+" do
            term.setCursorPos(1, q)
            term.write(aj)
            q = q + 1; if q > ag then
                term.scroll(1)
                q = q - 1
            end
        end
    end; term.setCursorPos(1, q)
    term.setTextColor(2)
    term.write("panic: We are hanging here...")
    mainThread = nil; while true do coroutine.yield() end
end
function wm.launch(fn)
    local task = loop:addTask(function()
        xpcall(fn,panic)
    end)
    task:setEventBlacklist {}
    return task
end
function wm.launchbg(fn)
    local task = loop:addTask(fn)
    task:setEventBlacklist {}
    return task
end

local function TaskMng()
    local w = window.create(term.native(),1,1,10,1)
    while true do
        local x,y = term.getCursorPos()
        w.setBackgroundColor(colors.gray)
        w.clear()
        w.setCursorPos(1,1)
        for i,p in pairs(loop.tasks) do
            
            w.write(tostring(i).." ")
        end
        term.setCursorPos(x,y)
        sleep(0.5)
    end
end

local sh = wm.launch(function()
    local w = window.create(term.native(),1,2,40,32)
    term.redirect(w)
    shell.run("shell")
end)

local function launcher()
    while true do
        local event, p1,h = os.pullEvent("key")
        if p1 == keys["f1"] then
            wm.launch(function()
                local w = window.create(term.native(),12,1,20,1)
                term.redirect(w)
                shell.run("shell")
            end)
        end
        if p1 == keys["f2"] then
            sh:pause()
        end
        if p1 == keys["f3"] then
            sh:unpause()
        end
    end
end
wm.launch(TaskMng)
wm.launch(launcher)


loop:run()