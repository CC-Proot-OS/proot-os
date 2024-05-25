local toml = require("toml")
local f = fs.open("/etc/repo.toml","r")
local repos = toml.decode(f.readAll())
f.close()

local args = {...}
local cmd = args[1]
local function sync()
    local pkgsD = {}
    local reposUsed = {}
    for key, value in pairs(repos) do
        if reposUsed[key] then
        else
            reposUsed[key]=true
            io.stdout:write("fetching repo "..key.."\n")
            local r = http.get(value.url.."packs.toml")
            local pk = toml.decode(r.readAll())
            for k, v in pairs(pk) do
                if v.location == "local" then
                    v.url = value.url..k..".toml"
                end
                io.stdout:write("fetching "..key.."."..k.."\n")
                local R = http.get(v.url)
                local pak = toml.decode(R.readAll())
                if pkgsD[k] then
                    pkgsD[key.."."..k] = pak.package
                else
                    pkgsD[k] = pak.package
                end
            end
        end
        
    end
    local f = fs.open("/var/cyclone/pkgs.ltn","wb")
    f.write(textutils.serialise(pkgsD))
    f.close()
end
local function updateIns(k,v)
    local f = fs.open("/var/cyclone/installed.toml","r")
    local pkgs = toml.decode(f.readAll())
    f.close()
    pkgs[k] = v
    f = fs.open("/var/cyclone/installed.toml","w")
    f.write(toml.encode(pkgs))
    f.close()
end
local function isIns(k)
    local f = fs.open("/var/cyclone/installed.toml","r")
    local pkgs = toml.decode(f.readAll())
    f.close()
    return pkgs[k]
end
local function add()
    local f = fs.open("/etc/repo.toml","w")
    repos[args[2]] = {url=args[3]}
    f.write(toml.encode(repos))
    f.close()
end
local function install(pki)
    local f = fs.open("/var/cyclone/pkgs.ltn","r")
    local pkgs = textutils.unserialize(f.readAll())
    f.close()
    local pk = pkgs[pki]
    if isIns(pki) then
        io.stdout:write(pki.." ["..isIns(pki).."]".." is installed\n")
    elseif pk then
        for key, value in ipairs(pk.depends) do
            if isIns(value) then
            else
                install(value)
            end
        end
        io.stdout:write("installing "..pki.."\n")
        local fa = fs.open("/usr/"..pk.type.."/"..pki..".lua","w")
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
    local pk = pkgs[pki]
    if pk then
    else
        return
    end
    if ((isIns(pki)or 0) >= (pk.ver or 0)) then
        io.stdout:write(pki.." ["..isIns(pki).."]".." is latest version\n")
    elseif isIns(pki) then
        for key, value in ipairs(pk.depends) do
            if (isIns(value)or 0) >= (pkgs[value].ver or 0) then
            else
                update(value)
            end
        end
        io.stdout:write("updating "..pki.."\n")
        local fa = fs.open("/usr/"..pk.type.."/"..pki..".lua","w")
        local R = http.get(pk.addr)
        fa.write(R.readAll())
        fa.close()
        updateIns(pki,pk.ver)
    end
end
local function updateAll()
    local f = fs.open("/var/cyclone/installed.toml","r")
    local pkgsI = toml.decode(f.readAll())
    f.close()
    for key, value in pairs(pkgsI) do
        update(key)
    end
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
    printWarning("Invalid Command")
end
