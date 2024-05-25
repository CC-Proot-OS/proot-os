local expect
_loggers = {}
kernel = {}
do
    local h = fs.open("rom/modules/main/cc/expect.lua", "r")
    local f, err = (_VERSION == "Lua 5.1" and loadstring or load)(h.readAll(), "@/rom/modules/main/cc/expect.lua")
    h.close()

    if not f then error(err) end
    expect = f().expect
end
local function prefix(chunkname)
    if type(chunkname) ~= "string" then return chunkname end
    local head = chunkname:sub(1, 1)
    if head == "=" or head == "@" then
        return chunkname
    else
        return "=" .. chunkname
    end
end

if _VERSION == "Lua 5.1" then
    -- If we're on Lua 5.1, install parts of the Lua 5.2/5.3 API so that programs can be written against it
    local type = type
    local nativeload = load
    local nativeloadstring = loadstring
    local nativesetfenv = setfenv

    function load(x, name, mode, env)
        expect(1, x, "function", "string")
        expect(2, name, "string", "nil")
        expect(3, mode, "string", "nil")
        expect(4, env, "table", "nil")

        local ok, p1, p2 = pcall(function()
            if type(x) == "string" then
                local result, err = nativeloadstring(x, name)
                if result then
                    if env then
                        env._ENV = env
                        nativesetfenv(result, env)
                    end
                    return result
                else
                    return nil, err
                end
            else
                local result, err = nativeload(x, name)
                if result then
                    if env then
                        env._ENV = env
                        nativesetfenv(result, env)
                    end
                    return result
                else
                    return nil, err
                end
            end
        end)
        if ok then
            return p1, p2
        else
            error(p1, 2)
        end
    end

    if _CC_DISABLE_LUA51_FEATURES then
        -- Remove the Lua 5.1 features that will be removed when we update to Lua 5.2, for compatibility testing.
        -- See "disable_lua51_functions" in ComputerCraft.cfg
        setfenv = nil
        getfenv = nil
        loadstring = nil
        unpack = nil
        math.log10 = nil
        table.maxn = nil
    else
        loadstring = function(string, chunkname) return nativeloadstring(string, prefix(chunkname)) end

        -- Inject a stub for the old bit library
        _G.bit = {
            bnot = bit32.bnot,
            band = bit32.band,
            bor = bit32.bor,
            bxor = bit32.bxor,
            brshift = bit32.arshift,
            blshift = bit32.lshift,
            blogic_rshift = bit32.rshift,
        }
    end
end
if not getfenv or not setfenv then
    -- setfenv/getfenv replacements from https://leafo.net/guides/setfenv-in-lua52-and-above.html
    function setfenv(fn, env)
        if not debug then error("could not set environment", 2) end
        if type(fn) == "number" then fn = debug.getinfo(fn + 1, "f").func end
        local i = 1
        while true do
            local name = debug.getupvalue(fn, i)
            if name == "_ENV" then
                debug.upvaluejoin(fn, i, (function()
                    return env
                end), 1)
                break
            elseif not name then
                break
            end

            i = i + 1
        end

        return fn
    end

    function getfenv(fn)
        if not debug then error("could not set environment", 2) end
        if type(fn) == "number" then fn = debug.getinfo(fn + 1, "f").func end
        local i = 1
        while true do
            local name, val = debug.getupvalue(fn, i)
            if name == "_ENV" then
                return val
            elseif not name then
                break
            end
            i = i + 1
        end
    end
end

function table.maxn(tab)
    local num = 0
    for k in pairs(tab) do
        if type(k) == "number" and k > num then
            num = k
        end
    end
    return num
end

math.log10 = function(x) return math.log(x, 10) end
loadstring = function(string, chunkname) return load(string, prefix(chunkname)) end
unpack = table.unpack


-- Install lua parts of the os api
function os.version()
    return "CraftOS 1.9"
end

function os.pullEventRaw(sFilter)
    return coroutine.yield(sFilter)
end

function os.pullEvent(sFilter)
    local eventData = table.pack(os.pullEventRaw(sFilter))
    if eventData[1] == "terminate" then
        error("Terminated", 0)
    end
    return table.unpack(eventData, 1, eventData.n)
end

-- Install globals
function sleep(nTime)
    expect(1, nTime, "number", "nil")
    local timer = os.startTimer(nTime or 0)
    repeat
        local _, param = os.pullEvent("timer")
    until param == timer
end

function Bwrite(sText)
    expect(1, sText, "string", "number")

    local w, h = term.getSize()
    local x, y = term.getCursorPos()

    local nLinesPrinted = 0
    local function newLine()
        if y + 1 <= h then
            term.setCursorPos(1, y + 1)
        else
            term.setCursorPos(1, h)
            term.scroll(1)
        end
        x, y = term.getCursorPos()
        nLinesPrinted = nLinesPrinted + 1
    end

    -- Print the line with proper word wrapping
    sText = tostring(sText)
    while #sText > 0 do
        local whitespace = string.match(sText, "^[ \t]+")
        if whitespace then
            -- Print whitespace
            term.write(whitespace)
            x, y = term.getCursorPos()
            sText = string.sub(sText, #whitespace + 1)
        end

        local newline = string.match(sText, "^\n")
        if newline then
            -- Print newlines
            newLine()
            sText = string.sub(sText, 2)
        end

        local text = string.match(sText, "^[^ \t\n]+")
        if text then
            sText = string.sub(sText, #text + 1)
            if #text > w then
                -- Print a multiline word
                while #text > 0 do
                    if x > w then
                        newLine()
                    end
                    term.write(text)
                    text = string.sub(text, w - x + 2)
                    x, y = term.getCursorPos()
                end
            else
                -- Print a word normally
                if x + #text - 1 > w then
                    newLine()
                end
                term.write(text)
                x, y = term.getCursorPos()
            end
        end
    end

    return nLinesPrinted
end
function writeUI(win,sText)
    expect(2, sText, "string", "number")

    local w, h = win.getSize()
    local x, y = win.getCursorPos()

    local nLinesPrinted = 0
    local function newLine()
        if y + 1 <= h then
            win.setCursorPos(1, y + 1)
        else
            win.setCursorPos(1, h)
            win.scroll(1)
        end
        x, y = win.getCursorPos()
        nLinesPrinted = nLinesPrinted + 1
    end

    -- Print the line with proper word wrapping
    sText = tostring(sText)
    while #sText > 0 do
        local whitespace = string.match(sText, "^[ \t]+")
        if whitespace then
            -- Print whitespace
            win.write(whitespace)
            x, y = win.getCursorPos()
            sText = string.sub(sText, #whitespace + 1)
        end

        local newline = string.match(sText, "^\n")
        if newline then
            -- Print newlines
            newLine()
            sText = string.sub(sText, 2)
        end

        local text = string.match(sText, "^[^ \t\n]+")
        if text then
            sText = string.sub(sText, #text + 1)
            if #text > w then
                -- Print a multiline word
                while #text > 0 do
                    if x > w then
                        newLine()
                    end
                    win.write(text)
                    text = string.sub(text, w - x + 2)
                    x, y = win.getCursorPos()
                end
            else
                -- Print a word normally
                if x + #text - 1 > w then
                    newLine()
                end
                win.write(text)
                x, y = win.getCursorPos()
            end
        end
    end

    return nLinesPrinted
end

local function writeANSI(nativewrite)
    return function(str)
        local seq = nil
        local bold = false
        local lines = 0
        local function getnum(d) 
            if seq == "[" then return d or 1
            elseif string.find(seq, ";") then return 
                tonumber(string.sub(seq, 2, string.find(seq, ";") - 1)), 
                tonumber(string.sub(seq, string.find(seq, ";") + 1)) 
            else return tonumber(string.sub(seq, 2)) end 
        end
        for c in string.gmatch(str, ".") do
            if seq == "\27" then
                if c == "c" then
                    term.setBackgroundColor(colors.black)
                    term.setTextColor(colors.white)
                    term.setCursorBlink(true)
                elseif c == "[" then seq = "["
                else seq = nil end
            elseif seq ~= nil and string.sub(seq, 1, 1) == "[" then
                if tonumber(c) ~= nil or c == ';' then seq = seq .. c else
                    debug.debug()
                    if c == "A" then term.setCursorPos(term.getCursorPos(), select(2, term.getCursorPos()) - getnum())
                    elseif c == "B" then term.setCursorPos(term.getCursorPos(), select(2, term.getCursorPos()) + getnum())
                    elseif c == "C" then term.setCursorPos(term.getCursorPos() + getnum(), select(2, term.getCursorPos()))
                    elseif c == "D" then term.setCursorPos(term.getCursorPos() - getnum(), select(2, term.getCursorPos()))
                    elseif c == "E" then term.setCursorPos(1, select(2, term.getCursorPos()) + getnum())
                    elseif c == "F" then term.setCursorPos(1, select(2, term.getCursorPos()) - getnum())
                    elseif c == "G" then term.setCursorPos(getnum(), select(2, term.getCursorPos()))
                    elseif c == "H" then term.setCursorPos(getnum())
                    elseif c == "J" then term.clear() -- ?
                    elseif c == "K" then term.clearLine() -- ?
                    elseif c == "T" then term.scroll(getnum())
                    elseif c == "f" then term.setCursorPos(getnum())
                    elseif c == "m" then
                        local n, m = getnum(0)
                        if n == 0 then
                            term.setBackgroundColor(colors.black)
                            term.setTextColor(colors.white)
                        elseif n == 1 then bold = true
                        elseif n == 7 or n == 27 then
                            local bg = term.getBackgroundColor()
                            term.setBackgroundColor(term.getTextColor())
                            term.setTextColor(bg)
                        elseif n == 22 then bold = false
                        elseif n >= 30 and n <= 37 then term.setTextColor(2^(15 - (n - 30) - (bold and 8 or 0)))
                        elseif n == 39 then term.setTextColor(colors.white)
                        elseif n >= 40 and n <= 47 then term.setBackgroundColor(2^(15 - (n - 40) - (bold and 8 or 0)))
                        elseif n == 49 then term.setBackgroundColor(colors.black) 
                        elseif n >= 90 and n <= 97 then
                            debug.debug()
                            term.setTextColor(2^(15 - (n - 90) - 8))
                        elseif n >= 100 and n <= 107 then term.setBackgroundColor(2^(15 - (n - 100) - 8))
                        end
                        if m ~= nil then
                            if m == 0 then
                                term.setBackgroundColor(colors.black)
                                term.setTextColor(colors.white)
                            elseif m == 1 then bold = true
                            elseif m == 7 or m == 27 then
                                local bg = term.getBackgroundColor()
                                term.setBackgroundColor(term.getTextColor())
                                term.setTextColor(bg)
                            elseif m == 22 then bold = false
                            elseif m >= 30 and m <= 37 then term.setTextColor(2^(15 - (m - 30) - (bold and 8 or 0)))
                            elseif m == 39 then term.setTextColor(colors.white)
                            elseif m >= 40 and m <= 47 then term.setBackgroundColor(2^(15 - (m - 40) - (bold and 8 or 0)))
                            elseif m == 49 then term.setBackgroundColor(colors.black) 
                            elseif n >= 90 and n <= 97 then term.setTextColor(2^(15 - (n - 90) - 8))
                            elseif n >= 100 and n <= 107 then term.setBackgroundColor(2^(15 - (n - 100) - 8)) end
                        end
                    elseif c == "z" then
                        local n, m = getnum(0)
                        if n == 0 then
                            term.setBackgroundColor(colors.black)
                            term.setTextColor(colors.white)
                        elseif n == 7 or n == 27 then
                            local bg = term.getBackgroundColor()
                            term.setBackgroundColor(term.getTextColor())
                            term.setTextColor(bg)
                        elseif n >= 25 and n <= 39 then term.setTextColor(n-25)
                        elseif n >= 40 and n <= 56 then term.setBackgroundColor(n-40)
                        end
                        if m ~= nil then
                            if m == 0 then
                                term.setBackgroundColor(colors.black)
                                term.setTextColor(colors.white)
                            elseif m == 7 or m == 27 then
                                local bg = term.getBackgroundColor()
                                term.setBackgroundColor(term.getTextColor())
                                term.setTextColor(bg)
                            elseif m >= 25 and m <= 39 then term.setTextColor(m-25)
                            elseif m >= 40 and m <= 56 then term.setBackgroundColor(m-40)
                        end
                    end
                    end
                    seq = nil
                end
            elseif c == string.char(0x1b) then seq = "\27"
            else lines = lines + (nativewrite(c) or 0) end
        end
        return lines
    end
end
write = writeANSI(Bwrite)

function print(...)
    local nLinesPrinted = 0
    local nLimit = select("#", ...)
    for n = 1, nLimit do
        local s = tostring(select(n, ...))
        if n < nLimit then
            s = s .. "\t"
        end
        nLinesPrinted = nLinesPrinted + write(s)
    end
    nLinesPrinted = nLinesPrinted + write("\n")
    return nLinesPrinted
end

function printWin(win,...)
    local nLinesPrinted = 0
    local nLimit = select("#", ...)
    for n = 1, nLimit do
        local s = tostring(select(n, ...))
        if n < nLimit then
            s = s .. "\t"
        end
        nLinesPrinted = nLinesPrinted + writeUI(win,s)
    end
    nLinesPrinted = nLinesPrinted + writeUI(win,"\n")
    return nLinesPrinted
end

function printError(...)
    local oldColour
    if term.isColour() then
        oldColour = term.getTextColour()
        term.setTextColour(colors.red)
    end
    print(...)
    if term.isColour() then
        term.setTextColour(oldColour)
    end
end


function printWarning(...)
    local oldColour
    if term.isColour() then
        oldColour = term.getTextColour()
        term.setTextColour(colors.yellow)
    end
    print(...)
    if term.isColour() then
        term.setTextColour(oldColour)
    end
end


function read(_sReplaceChar, _tHistory, _fnComplete, _sDefault)
    expect(1, _sReplaceChar, "string", "nil")
    expect(2, _tHistory, "table", "nil")
    expect(3, _fnComplete, "function", "nil")
    expect(4, _sDefault, "string", "nil")

    term.setCursorBlink(true)

    local sLine
    if type(_sDefault) == "string" then
        sLine = _sDefault
    else
        sLine = ""
    end
    local nHistoryPos
    local nPos, nScroll = #sLine, 0
    if _sReplaceChar then
        _sReplaceChar = string.sub(_sReplaceChar, 1, 1)
    end

    local tCompletions
    local nCompletion
    local function recomplete()
        if _fnComplete and nPos == #sLine then
            tCompletions = _fnComplete(sLine)
            if tCompletions and #tCompletions > 0 then
                nCompletion = 1
            else
                nCompletion = nil
            end
        else
            tCompletions = nil
            nCompletion = nil
        end
    end

    local function uncomplete()
        tCompletions = nil
        nCompletion = nil
    end

    local w = term.getSize()
    local sx = term.getCursorPos()

    local function redraw(_bClear)
        local cursor_pos = nPos - nScroll
        if sx + cursor_pos >= w then
            -- We've moved beyond the RHS, ensure we're on the edge.
            nScroll = sx + nPos - w
        elseif cursor_pos < 0 then
            -- We've moved beyond the LHS, ensure we're on the edge.
            nScroll = nPos
        end

        local _, cy = term.getCursorPos()
        term.setCursorPos(sx, cy)
        local sReplace = _bClear and " " or _sReplaceChar
        if sReplace then
            term.write(string.rep(sReplace, math.max(#sLine - nScroll, 0)))
        else
            term.write(string.sub(sLine, nScroll + 1))
        end

        if nCompletion then
            local sCompletion = tCompletions[nCompletion]
            local oldText, oldBg
            if not _bClear then
                oldText = term.getTextColor()
                oldBg = term.getBackgroundColor()
                term.setTextColor(colors.white)
                term.setBackgroundColor(colors.gray)
            end
            if sReplace then
                term.write(string.rep(sReplace, #sCompletion))
            else
                term.write(sCompletion)
            end
            if not _bClear then
                term.setTextColor(oldText)
                term.setBackgroundColor(oldBg)
            end
        end

        term.setCursorPos(sx + nPos - nScroll, cy)
    end

    local function clear()
        redraw(true)
    end

    recomplete()
    redraw()

    local function acceptCompletion()
        if nCompletion then
            -- Clear
            clear()

            -- Find the common prefix of all the other suggestions which start with the same letter as the current one
            local sCompletion = tCompletions[nCompletion]
            sLine = sLine .. sCompletion
            nPos = #sLine

            -- Redraw
            recomplete()
            redraw()
        end
    end
    while true do
        local sEvent, param, param1, param2 = os.pullEvent()
        if sEvent == "char" then
            -- Typed key
            clear()
            sLine = string.sub(sLine, 1, nPos) .. param .. string.sub(sLine, nPos + 1)
            nPos = nPos + 1
            recomplete()
            redraw()

        elseif sEvent == "paste" then
            -- Pasted text
            clear()
            sLine = string.sub(sLine, 1, nPos) .. param .. string.sub(sLine, nPos + 1)
            nPos = nPos + #param
            recomplete()
            redraw()

        elseif sEvent == "key" then
            if param == keys.enter or param == keys.numPadEnter then
                -- Enter/Numpad Enter
                if nCompletion then
                    clear()
                    uncomplete()
                    redraw()
                end
                break

            elseif param == keys.left then
                -- Left
                if nPos > 0 then
                    clear()
                    nPos = nPos - 1
                    recomplete()
                    redraw()
                end

            elseif param == keys.right then
                -- Right
                if nPos < #sLine then
                    -- Move right
                    clear()
                    nPos = nPos + 1
                    recomplete()
                    redraw()
                else
                    -- Accept autocomplete
                    acceptCompletion()
                end

            elseif param == keys.up or param == keys.down then
                -- Up or down
                if nCompletion then
                    -- Cycle completions
                    clear()
                    if param == keys.up then
                        nCompletion = nCompletion - 1
                        if nCompletion < 1 then
                            nCompletion = #tCompletions
                        end
                    elseif param == keys.down then
                        nCompletion = nCompletion + 1
                        if nCompletion > #tCompletions then
                            nCompletion = 1
                        end
                    end
                    redraw()

                elseif _tHistory then
                    -- Cycle history
                    clear()
                    if param == keys.up then
                        -- Up
                        if nHistoryPos == nil then
                            if #_tHistory > 0 then
                                nHistoryPos = #_tHistory
                            end
                        elseif nHistoryPos > 1 then
                            nHistoryPos = nHistoryPos - 1
                        end
                    else
                        -- Down
                        if nHistoryPos == #_tHistory then
                            nHistoryPos = nil
                        elseif nHistoryPos ~= nil then
                            nHistoryPos = nHistoryPos + 1
                        end
                    end
                    if nHistoryPos then
                        sLine = _tHistory[nHistoryPos]
                        nPos, nScroll = #sLine, 0
                    else
                        sLine = ""
                        nPos, nScroll = 0, 0
                    end
                    uncomplete()
                    redraw()

                end

            elseif param == keys.backspace then
                -- Backspace
                if nPos > 0 then
                    clear()
                    sLine = string.sub(sLine, 1, nPos - 1) .. string.sub(sLine, nPos + 1)
                    nPos = nPos - 1
                    if nScroll > 0 then nScroll = nScroll - 1 end
                    recomplete()
                    redraw()
                end

            elseif param == keys.home then
                -- Home
                if nPos > 0 then
                    clear()
                    nPos = 0
                    recomplete()
                    redraw()
                end

            elseif param == keys.delete then
                -- Delete
                if nPos < #sLine then
                    clear()
                    sLine = string.sub(sLine, 1, nPos) .. string.sub(sLine, nPos + 2)
                    recomplete()
                    redraw()
                end

            elseif param == keys["end"] then
                -- End
                if nPos < #sLine then
                    clear()
                    nPos = #sLine
                    recomplete()
                    redraw()
                end

            elseif param == keys.tab then
                -- Tab (accept autocomplete)
                acceptCompletion()

            end

        elseif sEvent == "mouse_click" or sEvent == "mouse_drag" and param == 1 then
            local _, cy = term.getCursorPos()
            if param1 >= sx and param1 <= w and param2 == cy then
                -- Ensure we don't scroll beyond the current line
                nPos = math.min(math.max(nScroll + param1 - sx, 0), #sLine)
                redraw()
            end

        elseif sEvent == "term_resize" then
            -- Terminal resized
            w = term.getSize()
            redraw()

        end
    end

    local _, cy = term.getCursorPos()
    term.setCursorBlink(false)
    term.setCursorPos(w + 1, cy)
    print()

    return sLine
end

function loadfile(filename, mode, env)
    -- Support the previous `loadfile(filename, env)` form instead.
    if type(mode) == "table" and env == nil then
        mode, env = nil, mode
    end

    expect(1, filename, "string")
    expect(2, mode, "string", "nil")
    expect(3, env, "table", "nil")

    local file = fs.open(filename, "r")
    if not file then return nil, "File not found" end

    local func, err = load(file.readAll(), "@/" .. fs.combine(filename), mode, env)
    file.close()
    return func, err
end

function dofile(_sFile)
    expect(1, _sFile, "string")

    local fnFile, e = loadfile(_sFile, nil, _G)
    if fnFile then
        return fnFile()
    else
        error(e, 2)
    end
end

local tAPIsLoading = {}
function os.loadAPI(_sPath)
    expect(1, _sPath, "string")
    local sName = fs.getName(_sPath)
    if sName:sub(-4) == ".lua" then
        sName = sName:sub(1, -5)
    end
    if tAPIsLoading[sName] == true then
        printError("API " .. sName .. " is already being loaded")
        return false
    end
    tAPIsLoading[sName] = true

    local tEnv = {}
    setmetatable(tEnv, { __index = _G })
    local fnAPI, err = loadfile(_sPath, nil, tEnv)
    if fnAPI then
        local ok, err = pcall(fnAPI)
        if not ok then
            tAPIsLoading[sName] = nil
            return error("Failed to load API " .. sName .. " due to " .. err, 1)
        end
    else
        tAPIsLoading[sName] = nil
        return error("Failed to load API " .. sName .. " due to " .. err, 1)
    end

    local tAPI = {}
    for k, v in pairs(tEnv) do
        if k ~= "_ENV" then
            tAPI[k] =  v
        end
    end

    _G[sName] = tAPI
    tAPIsLoading[sName] = nil
    return true
end

function os.unloadAPI(_sName)
    expect(1, _sName, "string")
    if _sName ~= "_G" and type(_G[_sName]) == "table" then
        _G[_sName] = nil
    end
end

function os.sleep(nTime)
    sleep(nTime)
end

local nativeShutdown = os.shutdown
function os.shutdown(...)
    nativeShutdown(...)
    while true do
        coroutine.yield()
    end
end

local nativeReboot = os.reboot
function os.reboot()
    nativeReboot()
    while true do
        coroutine.yield()
    end
end

local bAPIError = false
local function load_apis(dir)
    if not fs.isDir(dir) then return end

    for _, file in ipairs(fs.list(dir)) do
        if file:sub(1, 1) ~= "." then
            local path = fs.combine(dir, file)
            if not fs.isDir(path) then
                if not os.loadAPI(path) then
                    bAPIError = true
                end
            end
        end
    end
end




local function pal()
    local fg = term.getTextColor()
    local bg = term.getBackgroundColor()
    term.blit("0123456789abcdef","0123456789abcdef","0123456789abcdef")
    term.setTextColor(fg)
    term.setBackgroundColor(bg)
    print("")
end


load_apis("/sys/modules")

local curUsr = "root"
function kernel.getUser()
    return curUsr
end
function kernel.login(usr)
    curUsr = usr
end

term.setPaletteColor(2^0,0xFFFFFF)
term.setPaletteColor(2^1,0xFF6300)
term.setPaletteColor(2^2,0xFF00DE)
term.setPaletteColor(2^3,0x00C3FF)
term.setPaletteColor(2^4,0xFFFF00)
term.setPaletteColor(2^5,0x91FF00)
term.setPaletteColor(2^6,0xFF6DA8)
term.setPaletteColor(2^7,0x383737)
term.setPaletteColor(2^8,0xA9A9A9)
term.setPaletteColor(2^9,0x00FFFF)
term.setPaletteColor(2^10,0x7700FF)
term.setPaletteColor(2^11,0x0000DD)
term.setPaletteColor(2^12,0x4C2700)
term.setPaletteColor(2^13,0x00FF00)
term.setPaletteColor(2^14,0xFF0000)
term.setPaletteColor(2^15,0x000000)

local w,h = term.getSize()
local logWin = window.create(term.current(),1,1,w,h)

local mkrqr = dofile("/sys/lib/require.lua")
local env = setmetatable({}, { __index = _ENV })
env.require, env.package = mkrqr.make(env, "")

local logging = env.require("log")
local log  = logging.make("System",logWin)
local function panic(dat)
    log:critical(debug.traceback(dat))
    log:critical("System hanging")
    while true do
        coroutine.yield()
    end
end
log:info("Loading system")
log:debug("internals loaded")
log:debug("Modules loaded")
log:success("logger started")
log:success("require setup")

local fat = dofile("/sys/lib/fat.lua")
local reg
local bootSettings = {
    threads = false,
    showPal = false,
    theme = false,
    success = true
}
xpcall(function()
    reg = fat.proxy("/etc/reg.fs")
    log:info("Registry file loaded")
    bootSettings.threads = reg.exists("threads")
    bootSettings.showPal = not reg.exists("noShowPal")
    bootSettings.theme = not reg.exists("theme")
end,panic)
settings = {}
function settings.get(v,b)
    if reg.exists(v) then
        local f = reg.open(v,"r")
        local t = reg.read(f)
        reg.close(f)
        return t
    end
    return b
end
log:success("Registry bootdata loaded")
if bootSettings.theme then
    dofile("/etc/nightsShadow.lua")
    log:debug("SYS Theme - Into the nights shadow")
end

if not bootSettings.threads then
    log.critical([[ProotOS does not Support threadless mode]])
    bootSettings.success = false
end

if not bootSettings.success then
    log.warn("Invalid boot setup, Launching Regedit")
    xpcall(function ()
        dofile("/bin/regedit.lua")
    end,panic)
    panic()
end
log:info("Boot Setup")
log:info("Boot Setup")
local function makeTTY()
    local w,h = term.getSize()
    local tty = window.create(term.current(),1,1,w,h,false)
    return tty
end
local TTYS = {logWin,makeTTY(),makeTTY()}
function term.switch(id)
    --term.redirect(term.native())
    for index, value in ipairs(TTYS) do
        value.setVisible(false)
    end
    TTYS[id].setVisible(true)
    term.redirect(TTYS[id])
end

log:info("Loading FS")
local OFS =fs
local filesystem = {}
function filesystem.open(pth,md)
    if OFS.exists(OFS.combine("",pth)) then
        return OFS.open(OFS.combine("",pth),md)
    end
end
log:warn("FS not complete")
log:debug("Mounting Root")
log:debug("Mounting rom")

log:info("Starting Thread System")
log:debug("Using taskmaster thread system")
local loop = env.require("taskmaster")()
--[[if bootSettings.showPal then
    pal()
end]]
term.switch(2)
function os.start(func)
    local task = loop:addTask(function()
        xpcall(func,printWarning)
    end)
    task:setEventBlacklist {}
end
local KEYSPRS = {}
local nums = {
    [keys.one] = 1,
    [keys.two] = 2,
    [keys.three] = 3
}
loop:eventListener("key", function(ev, key)
    KEYSPRS[key]=true
    if KEYSPRS[keys.leftCtrl] then
        if nums[key] then
            term.switch(nums[key])
        end
    end
end)
loop:eventListener("key_up", function(ev, key) KEYSPRS[key]=false end)

loop:eventListener("char", function(ev, char)
    
end)


xpcall(function()
    
    --loop:setEventBlacklist {"key", "key_up", "char", "paste", "mouse_click", "mouse_up", "mouse_scroll", "mouse_drag"}

    local function fgFunc(task)
        log:info("Starting Kernel")
        while true do
            local event, p1 = os.pullEvent()
            if event == "char" and p1 == "q" then
                task:remove()
            end
        end
    end

    local task = loop:addTask(fgFunc)
    task:setEventBlacklist {}
    task:setPriority(10)

    local stmn = loadfile("/sys/bin/strtMng.lua","t",env)
    local strt = loop:addTask(function()
        stmn(loop)
    end)
    strt:setEventBlacklist {}
    strt:setPriority(9)

    log:success("Started Thread System")

    
    loop:run()
end,panic)

panic()