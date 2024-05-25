local loop = require("taskmaster")()
local function bgFunc()
    sleep(10)
    print("EEEEEEEEEEEEE")
end
local function pollingFunction()
    --os.pullEvent()
    print("2")
end
loop:setEventBlacklist { "key", "key_up", "char", "paste", "mouse_click", "mouse_up", "mouse_scroll", "mouse_drag" }
loop:addTask(bgFunc)
local p = loop:addTimer(2, pollingFunction)

local function fgFunc(task)
    while true do
        local event, p1 = os.pullEvent()
        if event == "char" and p1 == "q" then
            p:remove()
            task:remove()
            
        elseif event == "char" then
            print(p1)
        end
    end
end

local task = loop:addTask(fgFunc)
task:setEventBlacklist {}
task:setPriority(10)

loop:run()
