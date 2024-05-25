local arg = {...}
local loop = arg[1]
local attomic = require("attomic")
local sync = attomic.sync()
local user = attomic.attom()
local logging = dofile("/sys/lib/log.lua").load
local log  =logging("System")
log:notice("Welcome to ProotOS")
log:info("Locating drivers")
coroutine.yield()
log:debug("Drivers started")
log:warn("Drivers not implemented")

log:debug("Starting Services")
log:warn("Services not implemented")

local function userspace()
    while true do
        local u = user.get()
        log:debug("logged in",u)
        kernel.login(u)
        term.switch(2)
        term.clear()
        term.setCursorPos(1,1)
        loadfile("/bin/cash.lua","t",_ENV)()
    end
end


log:debug("Starting Login")
local login = loadfile("/sys/bin/login.lua")
local loginTsk = loop:addTask(function(task)
    login(task,sync,user)
end)
loginTsk:setEventBlacklist {}
loginTsk:setPriority(8)

local UsrSpace = loop:addTask(function(task)
    userspace(task,sync,user)
end)
UsrSpace:setEventBlacklist {}
UsrSpace:setPriority(9)