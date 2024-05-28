local toml = require("toml")
local f = fs.open("/etc/repo.ltn","r")
local repos = textutils.unserialize(f.readAll())
f.close()

local args = {...}
local cmd = args[1]
local function getPkgData(pki)
    local f = fs.open("/var/cyclone/pkgs.ltn","r")
    local pkgs = textutils.unserialize(f.readAll())
    f.close()
    local pk = pkgs[pki]
    if pk.SIMLNK then
        pk = pkgs[pk.SIMLNK]
    end
    return pk
end
local function sync()
    io.stdout:write("syncing package lists\n")
    local pkgsD = {}
    local pkgsL = {}
    local reposUsed = {}
    for key, value in pairs(repos) do
        if reposUsed[key] then
        else
            reposUsed[key]=true
            io.stdout:write("fetching repo "..key.."\n")
            local r = http.get(value.url.."packs.toml")
            local pk = toml.decode(r.readAll())
            --print(textutils.serialise(pk))
            for k, v in pairs(pk) do
                if v.location == "local" then
                    v.url = value.url..k..".toml"
                end
                io.stdout:write("fetching "..key.."."..k.."\n")
                local R = http.get(v.url)
                local pak = toml.decode(R.readAll())
                pak.package.nmx = k
                if pkgsL[k] then
                    pkgsD[key.."."..k] = pak.package
                    pkgsL[key.."."..k] = true
                    
                else
                    pkgsD[k] = {SIMLNK=key.."."..k}
                    pkgsD[key.."."..k] = pak.package
                    pkgsL[k] = true
                    pkgsL[key.."."..k] = true
                end
            end
        end
        
    end
    local f = fs.open("/var/cyclone/pkgs.ltn","wb")
    f.write(textutils.serialise(pkgsD))
    f.close()
end
local function updateIns(k,v)
    local f = fs.open("/var/cyclone/installed.ltn","r")
    local pkgs = textutils.unserialize(f.readAll())
    f.close()
    pkgs[k] = v
    f = fs.open("/var/cyclone/installed.ltn","w")
    f.write(textutils.serialise(pkgs))
    f.close()
end
local function isIns(k)
    local f = fs.open("/var/cyclone/installed.ltn","r")
    local pkgs = textutils.unserialize(f.readAll())
    f.close()
    return pkgs[k]
end
local function add()
    local f = fs.open("/etc/repo.ltn","w")
    repos[args[2]] = {url=args[3]}
    f.write(textutils.serialise(repos))
    f.close()
end
local function pkgPath(pk)
    local pki = pk.nmx
    if pk.fname then
        pki = pk.fname
    end
    if pk.loc then
        return pk.loc.."/"..pki..".lua"
    else
        return "/usr/"..pk.type.."/"..pki..".lua"
    end
end
local function install(pki)
    local pk = getPkgData(pki)
    if isIns(pki) then
        io.stdout:write(pki.." ["..isIns(pki).."]".." is installed\n")
    elseif pk then
        for key, value in ipairs(pk.depends or {}) do
            if isIns(value) then
            else
                install(value)
            end
        end
        io.stdout:write("installing "..pki.."\n")
        local fa = fs.open(pkgPath(pk),"w")
        local R = http.get(pk.addr)
        fa.write(R.readAll())
        fa.close()
        updateIns(pki,pk.ver)
    end
    

end
local function update(pki)
    local f = fs.open("/var/cyclone/pkgs.ltn","r")
    local pkgs = textutils.unserialize(f.readAll())
    f.close()
    local pk = getPkgData(pki)
    if pk then
    else
        return
    end
    if ((isIns(pki)or 0) >= (pk.ver or 0)) then
        io.stdout:write(pki.." ["..isIns(pki).."]".." is latest version\n")
    elseif isIns(pki) then
        for key, value in ipairs(pk.depends or {}) do
            if (isIns(value)or 0) >= (pkgs[value].ver or 0) then
            else
                update(value)
            end
        end
        io.stdout:write("updating "..pki.."\n")
        local fa = fs.open(pkgPath(pk),"w")
        local R = http.get(pk.addr)
        fa.write(R.readAll())
        fa.close()
        updateIns(pki,pk.ver)
    end
end
local function updateAll()
    local f = fs.open("/var/cyclone/installed.ltn","r")
    local pkgsI = textutils.unserialize(f.readAll())
    f.close()
    for key, value in pairs(pkgsI) do
        update(key)
    end
end
if cmd == "-s" then
    table.remove(args,1)
    cmd = args[1]
    sync()
end
if cmd == "-S" then
    sync()
elseif cmd == "-A" then
    add()
elseif cmd == "-I" then
    install(args[2])
elseif cmd == "-U" then
    update(args[2])
elseif cmd == "-Ua" then
    updateAll()
else
    io.stderr:write("Invalid Command\n")
end