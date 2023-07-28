local Organ = {playing=false}

function Organ.Play(filePath, organ, side)
    Organ.playing = true
    local file = fs.open(filePath, "r")
    local commentBlock = false
    local sleep = os.sleep

    while true do
        local line = file.readLine()
        if not line then break end

        if line:find("/%*") then
            commentBlock = true
        elseif line:find("%*/") then
            commentBlock = false
        elseif line:find("//") or commentBlock then
        elseif line:find("delay") then
            local _, fin = line:find("delay")
            local delayTime = line:sub(fin+2, line:len())
            sleep(tonumber(delayTime))
        elseif line:find("mute") then
            for _, pipes in pairs(organ) do
                pipes(side, false)
            end
        elseif line:find("note") then
            local _, finNote = line:find("note")
            local begPipe, finPipe = line:find("pipe")

            local note = line:sub(finNote+2, begPipe-2)
            local pipe = line:sub(finPipe+2, line:len())
            local index = pipe.."_"..note

            organ[index](side, true)
        end
    end
end

function Organ.CreateVerificationFile(fileName, delay, configContent)
    local file = fs.open(fileName..".org", "w")

    file.write("//Verification File for the whole Organ. Auto Generated\n")
    for i=1, #configContent do
        file.write(string.format([[
delay %f
mute
note %s pipe %s
]], delay, configContent[i].note, configContent[i].pipe))
    end
    file.write("mute")
    file.close()
end

return Organ