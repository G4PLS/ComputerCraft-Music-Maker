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

rednet.host("organ", "main")
rednet.open(side)

args = {...} -- File name
filePath = args[1]..".organ"

if filePath == nil or fs.exists(filePath) ~= true then
    print("File not Found")
    return
end

file = fs.open(filePath, "r") --Read File
mon = peripheral.wrap("top") --Get monitor
mon = nil

--Checks if monitor is connected
if mon ~= nil then
    mon.setCursorPos(1,1)
    mon.write("Now Playing: "..args[1])
end

rednet.broadcast("start", "organ")
os.sleep(1)

local commentBlock = false

while true do
    local line = file.readLine()
    if not line then break end

    if line:find("/%*") then
        commentBlock = true
    elseif line:find("%*/") then
        commentBlock = false
    elseif line:find("//") or commentBlock == true then --Comment in the Organ file. Do nothing
    elseif line:find("delay") then
        --delay to the next note
        beg, fin = line:find("delay")
        delayTime = line:sub(fin + 2, line:len())
        delayTime = tonumber(delayTime)
        os.sleep(delayTime)
    elseif line:find("mute") then
        rednet.broadcast("mute", "organ")
    elseif line:find("note") then
        --Finds the Note, Pipe and if the note is a single note
        begNote, finNote = line:find("note")
        begPipe, finPipe = line:find("pipe")
        begSing, finSing = line:find("single")

        --Gets the note and organ
        note = line:sub(finNote + 2, begPipe - 2)

        if begSing == nil then
            organ = line:sub(finPipe + 2, line:len())
        else
            organ = line:sub(finPipe + 2, begSing - 2)
        end

        sendArgs = {note, organ}

        --Adds the single argument to the sending args
        if begSing ~= nil then
            table.insert(sendArgs, "single")
        end

        --Sends the args
        rednet.broadcast(sendArgs, "organ")

        if mon ~= nil then
            mon.clear()
            mon.setCursorPos(1,1)
            mon.write("Organ:"..organ.." Note:"..note)
        end
    end
end

rednet.broadcast("end", "organ")

if mon ~= nil then
    mon.clear()
    mon.setCursorPos(1,1)
    mon.write("Finished Playing:"..args[1])
end

file.close()