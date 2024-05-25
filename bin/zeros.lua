local args = {...}
 
local dev = args[1] or error("Must specify a file")
local sec = tonumber(args[2])*512
local device = fs.open(dev, "wb")
for i = 1, sec, 1 do
    device.write("\x00")
end
device.close()