local Organ = {playing=false}

function Organ.Play(filePath, organ, side)
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
        elseif line:match("delay%s%d*%.?%d+") then
            local delay = line:match("delay%s%d*%.?%d+")
            local _, fin = delay:find("delay")
            local delayTime = delay:sub(fin+2, line:len())
            sleep(tonumber(delayTime))
        elseif line:find("mute") then
            local mute = line:match("mute%snote%s%S+%spipe%s%S+") or line:match("mute%spipe%s%S+") or line:match("mute")
            if mute ~= nil and mute:find("note") then
                local _, finNote = mute:find("note")
                local begPipe, finPipe = mute:find("pipe")

                local note = line:sub(finNote+2, begPipe-2)
                local pipe = line:sub(finPipe+2, mute:len())
                local index = pipe.."_"..note

                organ[index](side, false)
            elseif mute ~= nil and mute:find("pipe")then
                local _, finPipe = mute:find("pipe")
                local pipeName = mute:sub(finPipe+2, mute:len())

                for key, pipe in pairs(organ) do
                    local underScore = key:find("_")
                    local pipeKey = key:sub(1,underScore-1)
                    if pipeKey:find(pipeName) and pipeKey:len() == pipeName:len() then
                        pipe(side, false)
                    end
                end
            elseif mute ~= nil then
                for _, pipes in pairs(organ) do
                    pipes(side, false)
                end
            end
        elseif line:find("play") then
            local play = line:match("play%snote%s%S+%spipe%s.+") or line:match("play%spipe%s%S+")
            if play ~= nil and play:find("note") then
                local _, finNote = play:find("note")
                local begPipe, finPipe = play:find("pipe")

                local note = play:sub(finNote+2, begPipe-2)
                local pipe = play:sub(finPipe+2, play:len())
                local index = pipe.."_"..note

                if organ[index]~= nil then organ[index](side, true) end
            elseif play ~= nil and play:find("pipe") then
                local _, finPipe = play:find("pipe")
                local pipeName = play:sub(finPipe+2, play:len())

                for key, pipe in pairs(organ) do
                    local underScore = key:find("_")
                    local pipeKey = key:sub(1,underScore-1)
                    if pipeKey:find(pipeName) and pipeKey:len() == pipeName:len() then
                        pipe(side, true)
                    end
                end
            end
        end
    end
end

function Organ.CreateVerificationFile(fileName, delay, configContent)
    local file = fs.open(fileName, "w")

    file.write("//Verification File for the whole Organ. Auto Generated\n")
    for i=1, #configContent do
        file.write(string.format([[
delay %.2f
mute
play note %s pipe %s
]], delay, configContent[i].note, configContent[i].pipe))
    end
    file.write("delay "..delay.."\nmute")
    file.close()
end

return Organ