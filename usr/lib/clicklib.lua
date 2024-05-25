local applib = require("applib")
local function click(x,y,bs)
    for i=1, #bs do
        if x >= bs[i].sx and x <= bs[i].ex then
            if y >= bs[i].sy and y <= bs[i].ey then
                bs[i].run(bs[i])
            end
        end
    end
end
local function draw(bs)
    for i=1, #bs do
        if bs[i].sy == bs[i].ey and bs[i].sy ~= nil then
            applib.writePos(bs[i].sx,bs[i].sy-1,bs[i].text,bs[i].bg,bs[i].fg)
        end
    end
end
return {click=click,draw=draw}
