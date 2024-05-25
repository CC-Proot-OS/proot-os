term.setBackgroundColor(colors.black)
term.setTextColor(colors.white)
NFT = require("cc.image.nft")
local NftImages = {
	blank = '\0308\0317\153\153\153\153\153\153\153\153\010\0307\0318\153\153\153\153\153\153\153\153\010\0308\0317\153\153\153\153\153\153\153\153\010\0307\0318\153\153\153\153\153\153\153\153\010\0308\0317\153\153\153\153\153\153\153\153',
	rom   = '\030 \031 \128\0318\144\144\144\144\144\031 \128\010\0308\031 \157\0307\0317\128\128\128\128\128\030 \0318\145\010\030 \0318\136\0307\0317\128\0307\0310ROM\0307\128\030 \0318\132\010\0308\031 \157\0307\0317\128\128\128\128\128\030 \0318\145\010\030 \031 \128\0318\129\129\129\129\129\031 \128',
	hdd   = '\030 \031  \0307\0317\128\0300\135\131\139\0307\128\010\030 \031  \0300\0317\149\0310\128\0307\131\0300\128\0307\149\010\030 \031  \0307\0310\130\0300\0317\144\0308\0310\133\0307\159\129\010\030 \031  \0308\0317\149\129\142\159\0307\128\010\030 \031  \030 \0317\143\143\143\143\143',
    drive = '\030 \031  \030b\031b\128\0308\0318\128\128\030f\149\030b\149\031 \139\010\030 \031  \030b\031b\128\128\128\128\128\128\010\030 \031  \030b\031b\128\0300\0317____\030b\031b\128\010\030 \031  \030b\031b\128\0300\0317____\030b\031b\128',
}
seldrive = "hdd"
local applib = require("applib")
local click= require("clicklib")

local function hddclk()
    seldrive = "hdd"
end
local function romclk()
    seldrive = "rom"
end
local function btnclk(btn)
    seldrive = btn.id
end
local function getDrives()
	local unique = { ['hdd'] = true, ['virt'] = true }
	local drives = { { text = ' hdd ',id="hdd",sx=2,sy=3,ex=7,ey=3,run=hddclk,fg=colors.white,bg=colors.blue} }
    i=1
	for _, drive in pairs(fs.list('/')) do
		local side = fs.getDrive(drive)
		if side and not unique[side] then
			unique[side] = true
			table.insert(drives, { text = ' '..drive..' ',id=drive,sx=2,sy=3+i,ex=7,ey=3+i,run=btnclk,fg=colors.white,bg=colors.gray})
            i=i+1
		end
	end
	return drives
end

--local bs = {{sx=2,sy=4,ex=7,ey=4,run=hddclk,text=" hdd ",fg=colors.white,bg=colors.red},{sx=2,sy=5,ex=7,ey=5,run=romclk,text=" rom ",fg=colors.white,bg=colors.blue}}
local bs = getDrives()
applib.clear()
local sx,sy = applib.getSize()
local function border()
    applib.writePos(1,1,string.rep("\127",sx),colors.black,colors.gray)
    applib.writevert(1,1,sy-1,"\127",colors.black,colors.gray)
    applib.writePos(1,sy,string.rep("\127",sx),colors.black,colors.gray)
    applib.writevert(sx,1,sy-1,"\127",colors.black,colors.gray)
    -- devider line
    applib.writePos(1,sy-6,string.rep("\127",sx),colors.black,colors.gray)
end
local function drawIcon(img)
    local rom = NFT.parse(img)
    NFT.draw(rom,2,(sy-6)+2)
end
local function round(a)
    return math.floor(a+0.5)
end
local function units(bytes)
    if bytes < 1000 then
        return bytes.." b"
    elseif bytes < 1000000 then
        return round((bytes/1000)).." kb"
    elseif bytes < 1000000000 then
        return round(((bytes/1000)/1000)).." mb"
    else
        return round((((bytes/1000)/1000)/1000)).." gb"
    end
end

local s = {l=0,t=0}
local ok, err = pcall(function()
    while true do
        applib.clear("drives")
        border()
        --applib.writePos(2,3," hdd ",colors.blue,colors.white)
        --applib.writePos(2,5," rom ",colors.red,colors.white)
        click.draw(bs)
        if seldrive =="rom" then
            drawIcon(NftImages.rom)
            applib.writePos(9,sy-5,"drive: rom",colors.black,colors.white)
            s.l = fs.getFreeSpace("rom/")
            s.t = 1
        elseif seldrive =="hdd" then
            drawIcon(NftImages.hdd)
            applib.writePos(9,sy-5,"drive: hdd",colors.black,colors.white)
            s.l = fs.getFreeSpace("/")
            s.t = fs.getCapacity("/")
        else
            drawIcon(NftImages.drive)
            applib.writePos(9,sy-5,"drive: "..seldrive,colors.black,colors.white)
            s.l = fs.getFreeSpace(seldrive.."")
            s.t = fs.getCapacity(seldrive.."")
        end
        applib.writePos(9,sy-4,"size:"..units(s.t),colors.black,colors.white)
        applib.writePos(9,sy-3,"left:"..units(s.l),colors.black,colors.white)
        applib.writePos(9,sy-2,string.rep("\127",((s.t-s.l)/s.t)*((sx/4)*3)),colors.black,colors.green)
        applib.writePos(9+((s.t-s.l)/s.t)*((sx/4)*3),sy-2,string.rep("\127",(s.l/s.t)*((sx/4)*3)),colors.black,colors.gray)
        local event, button, x, y = os.pullEvent("mouse_click")
        click.click(x,y,bs)
end
end
)
print(err)
