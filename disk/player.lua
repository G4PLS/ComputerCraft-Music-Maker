--Check if conf file exists and create if it doesnt
if not fs.exists("player.conf") then
    local file = fs.open("player.conf", "w")
    file.write("pipe=1\n")
    file.write("note=F#")
    print("Config got created with, note=F# and pipe=1")
    print("To change this edit the config file")
    print("Program closes because config file got created for first time...")
    file.close()
    return
end

--Read conf file
local file = fs.open("player.conf", "r")
while true do
    local line = file.readLine()
    if not line then break end

    if line:find("note") then
        local _, fin = line:find("=")
        playNote = line:sub(fin + 1, line:len())
    elseif line:find("pipe") then
        local _, fin = line:find("=")
        organID = line:sub(fin + 1, line:len())
    end
end

peripherals = peripheral.getNames()

for _, value in pairs(peripherals) do
    if peripheral.getType(value) == "modem" then
        side = value
        break
    end
end

if side == nil then
    print("No modem Found")
    return
end

rednet.open(side)
print("Starting Organ: " .. organID .. " Note: " .. playNote)

redstoneOut = "back"

while true do
    _, message = rednet.receive("organ")

    if type(message) == "table" then
        if message[1] == playNote and message[2] == organID then
            if message[3] == "single" then
                redstone.setOutput(redstoneOut, true)
                os.sleep(0)
                redstone.setOutput(redstoneOut, false)
            else
                out = redstone.getOutput(redstoneOut)
                redstone.setOutput(redstoneOut, not out)
            end
        end
    elseif message == "start" then
        redstone.setOutput(redstoneOut, false)
        print("Starting next song")
    elseif message == "end" then
        redstone.setOutput(redstoneOut, false)
        print("Song ended")
    elseif message == "mute" then
        redstone.setOutput(redstoneOut, false)
    end
end
