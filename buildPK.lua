local function writeFile(pth,tx)
    local f = fs.open(pth,"w")
    f.write(tx)
    f.close()
end
local pklst = ""
local master = ""
local inx = ""
for index, value in ipairs(fs.list("/sys/modules")) do
    local nm = string.gsub(value,".lua",".toml")
    local n = string.gsub(value,".lua","")
    writeFile("/pkg/"..nm,string.format([[%s
    type="lib"
    loc = "/sys/modules"
    addr="https://raw.githubusercontent.com/CC-Proot-OS/proot-os/master/sys/modules/%s"
    ver=1
    depends=%s]],"[package]",value,"[]"))
    pklst = pklst..string.format('[%s]\nlocation = "local"\n\n',n)
    master = master .. string.format('"prootsys.%s",',n)
    inx = inx .. string.format('shell.run("/usr/bin/cyclone -I prootsys.%s")\n',n)
end
writeFile("/pkg/main.toml",string.format([[%s
    type="lib"
    loc = "/sys/modules"
    addr="https://raw.githubusercontent.com/CC-Proot-OS/proot-os/master/sys/modins.lua"
    ver=1
    depends=%s]],"[package]",string.format("[%s]",master)))
pklst = pklst..string.format('[%s]\nlocation = "local"\n\n',"main")
writeFile("/pkg/packs.toml",pklst)
writeFile("/pkg/inx.lua",inx)