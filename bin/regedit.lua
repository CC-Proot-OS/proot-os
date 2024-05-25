debug.debug()
local fat = dofile("/sys/lib/fat.lua")
local reg = fat.proxy("/etc/reg.fs")
term.switch(2)
local function prompt(e)
    write(e..">")
    return read()
end
while true do
    local cmd = prompt("REGEDIT")
    if cmd == "set" then
        local f = reg.open(prompt("REGEDIT/SET"),"w")
        reg.write(f,"SET")
        reg.close(f)
    elseif cmd == "del" then
        reg.remove(prompt("REGEDIT/DEL"))
    elseif cmd == "lst" then
        for key, value in ipairs(reg.list("")) do
            print(key,value)
        end
    elseif cmd == "ext" then
        return
    end
end