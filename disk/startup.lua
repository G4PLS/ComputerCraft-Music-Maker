print("1: Setup Organ | 2: Setup Player")
inp = read()

if inp == "1" then
    if fs.exists("organ.lua") then
        fs.delete("organ.lua")
    end
    fs.copy("disk/organ.lua", "organ.lua")
elseif inp == "2" then
    if fs.exists("startup") then
        fs.delete("startup")
    end
    fs.copy("disk/player.lua", "startup")
else
    print("Not a valid input")
    os.reboot()
end
os.shutdown()
