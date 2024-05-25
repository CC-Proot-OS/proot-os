local arg = {...}
local sync = arg[2]
local usync = arg[3]
local tsk = arg[1]
usync.take()
local w,h = term.getSize()
local win = window.create(term.current(),1,1,w,h)
term.redirect(win)
while true do
    term.setBackgroundColor(colors.black)
    term.setTextColor(colors.cyan)
    term.setCursorPos(1,1)
    print("ProotOS\n")
    print(type(({...})[1]))
    term.setTextColor(colors.white)
    write("LOGIN > ")
    local uname = read()
    usync.set(uname)
    break
end
win.setVisible(false)