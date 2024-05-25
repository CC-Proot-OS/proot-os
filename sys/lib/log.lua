local levels = {
    debug = colors.gray,
    info = colors.white,
    notice = colors.blue,
    warn = colors.orange,
    critical = colors.red,
    success = colors.green
}
local expect = dofile("rom/modules/main/cc/expect.lua").expect

local function load(id)
    if _loggers[id] then
        _loggers[id]:debug("Loaded logger")
        return _loggers[id]
    end
    error("no logger")
end

local function makeLoger(id,win)
    --local Win = win
    if _loggers[id] then
        error("exists")
    else
        expect(2,win,"table")
        local log = {}
        log.win = win
        function log:print(lvl,...)
            self.win.setVisible(true)
            local fg = self.win.getTextColor()
            self.win.setTextColor(levels[lvl])
            printWin(self.win,string.format("[%3s][%8s]",id,lvl),...)
            self.win.setTextColor(fg)
            if self.win.redraw then
                self.win.redraw()
            end
        end
        function log:debug(...)
            self:print("debug",...)
        end
        function log:info(...)
            self:print("info",...)
        end
        function log:notice(...)
            self:print("notice",...)
        end
        function log:warn(...)
            self:print("warn",...)
        end
        function log:critical(...)
            self:print("critical",...)
        end
        function log:success(...)
            self:print("success",...)
        end
        if id then
            _loggers[id] = log
        end
        return log
    end
end
return {make=makeLoger,load=load}