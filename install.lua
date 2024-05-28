io.stdout:write("Installing Cyclone")
local function mkdir(dir)
    if not fs.exists(dir) then
        fs.makeDir(dir)
    end
end
local function writeFile(pth,tx)
    local f = fs.open(pth,"w")
    f.write(tx)
    f.close()
end
mkdir("/var")
mkdir("/var/cyclone")
mkdir("/usr")
mkdir("/usr/bin")
mkdir("/usr/lib")
mkdir("/etc")
mkdir("/startup")
writeFile("/etc/repo.ltn",[[{
    proot = {
      url = "https://raw.githubusercontent.com/CC-Proot-OS/proot-cycl/main/",
    },
    cycl = {
      url = "https://raw.githubusercontent.com/CC-Proot-OS/CycloneRepo/main/",
    },
    prootsys = {
        url = "https://raw.githubusercontent.com/CC-Proot-OS/intrnl-cycl/main/",
    },
}]])


writeFile("/var/cyclone/installed.ltn",[[{
  cyclone = 0,
}
]])
shell.run("wget https://raw.githubusercontent.com/CC-Proot-OS/proot-os/master/sys/lib/toml.lua /usr/lib/toml.lua")
--shell.setDir("/usr/lib")

shell.run("wget https://raw.githubusercontent.com/CC-Proot-OS/Cyclone/main/cyclone.lua /usr/bin/cyclone.lua")
package.path = package.path .. ";/usr/lib/?;/usr/lib/?.lua;/usr/lib/?/init.lua"
shell.run("/usr/bin/cyclone -s -U cyclone")
io.stdout:write("Installing ProotOS")
shell.run("/usr/bin/cyclone -I proot.kernel")
shell.run("/usr/bin/cyclone -I proot.cash")
shell.run("/usr/bin/cyclone -I proot.regedit")
shell.run("/usr/bin/cyclone -I proot.mkfs")
shell.run("/usr/bin/cyclone -I proot.zeros")

shell.run("/usr/bin/cyclone -I prootsys.colors")
shell.run("/usr/bin/cyclone -I prootsys.colours")
shell.run("/usr/bin/cyclone -I prootsys.disk")
shell.run("/usr/bin/cyclone -I prootsys.fs")
shell.run("/usr/bin/cyclone -I prootsys.gps")
shell.run("/usr/bin/cyclone -I prootsys.help")
shell.run("/usr/bin/cyclone -I prootsys.http")
shell.run("/usr/bin/cyclone -I prootsys.io")
shell.run("/usr/bin/cyclone -I prootsys.keys")
shell.run("/usr/bin/cyclone -I prootsys.paintutils")
shell.run("/usr/bin/cyclone -I prootsys.parallel")
shell.run("/usr/bin/cyclone -I prootsys.peripheral")
shell.run("/usr/bin/cyclone -I prootsys.rednet")
shell.run("/usr/bin/cyclone -I prootsys.settings")
shell.run("/usr/bin/cyclone -I prootsys.term")
shell.run("/usr/bin/cyclone -I prootsys.textutils")
shell.run("/usr/bin/cyclone -I prootsys.vector")
shell.run("/usr/bin/cyclone -I prootsys.window")


shell.run("/bin/zeros /etc/reg.fs 512")
shell.run("/bin/mkfs /etc/reg.fs")
--os.reboot()