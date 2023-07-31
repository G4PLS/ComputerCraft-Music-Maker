local basalt = require("basalt")
local player = require("player")
local config = require("config")
require("helper")

local outputSide = "top"
local organ = config.Check(peripheral.getNames())
local confContent = config.Check(peripheral.getNames(), 1)
local getOrgan = config.Check(peripheral.getNames(), 2)

local modem = peripheral.find("modem")
local frequency = 10
local maxDistance = 10
local connectedFrequency = nil
local listening = true
local isOpen = false
local organFilePath = "OrganFiles/"
local fileEnd = ".org"

outputSide = loadStartupFile(outputSide)

if not fs.exists(organFilePath) then fs.makeDir(organFilePath) end

local mainFrame = basalt.createFrame()

-- UI DEFINITION
local menubar = mainFrame:addMenubar():setSize("parent.w-13"):setBackground(colors.gray):setForeground(colors.lightGray)
    :addItem("Organ")
    :addItem("Pipes")
    :addItem("Connection")

local btnRegenerateConf = mainFrame:addButton():setSize(13,1):setPosition("parent.w-12"):setText("New Config"):setBackground(colors.red):setForeground(colors.orange)
local subFrames = {
    mainFrame:addFrame():setPosition(1,2):setSize("parent.w", "parent.h-1"),
    mainFrame:addFrame():setPosition(1,2):setSize("parent.w", "parent.h-1"):hide(),
    mainFrame:addFrame():setPosition(1,2):setSize("parent.w", "parent.h-1"):hide()
}

local fileFrame = subFrames[1]:addFrame():setSize("(parent.w-1) * 0.5", "parent.h")
local editFrame = subFrames[1]:addFrame():setSize("parent.w * 0.5", "parent.h"):setPosition("parent.w * 0.5",1)

local fileList = fileFrame:addList():setSize("parent.w", "parent.h - 3"):setBackground(colors.lightGray):setForeground(colors.black)
local btnNew = fileFrame:addButton():setSize("parent.w*0.5", 1):setPosition("parent.w*0.5", "parent.h"):setText("NEW"):setBackground(colors.white)
local btnDelete = fileFrame:addButton():setSize("(parent.w-1)*0.5", 1):setPosition(1,"parent.h"):setText("DELETE"):setBackground(colors.red)
local inputFileName = fileFrame:addInput():setSize("parent.w ",1):setPosition(1, "parent.h-2"):setInputLimit(24):setDefaultText("File Name"):setBackground(colors.white)

local editField = editFrame:addTextfield():setSize("parent.w", "parent.h - 1"):setBackground(colors.black):setForeground(colors.white)
    :addRule("//.*", colors.green) -- WORKING
    --:addRule("/%*[%s%S]-%*/", colors.green) -- NOT WORKING
    :addRule("play%snote%s%S+%spipe%s.+", colors.yellow) -- WORKING
    :addRule("play%spipe%s%S+", colors.yellow) -- WORKING
    :addRule("mute", colors.red) -- WORKING
    :addRule("mute%snote%s%S+%spipe%s%S+", colors.red) -- WORKING
    :addRule("mute%spipe%s%S+", colors.red) -- WORKING
    :addRule("delay%s%d*%.?%d+", colors.lightBlue) -- WORKING

local btnSaveFile = editFrame:addButton():setSize("(parent.w-1)*0.5",1):setPosition(1,"parent.h"):setText("SAVE"):setBackground(colors.green)
local btnPlay = editFrame:addButton():setSize("parent.w*0.5",1):setPosition("(parent.w+1)*0.5","parent.h"):setText("PLAY"):setBackground(colors.yellow)

local pipesFrame = subFrames[2]:addFrame():setSize("(parent.w-1)*0.5","parent.h"):setBackground(colors.green)
local configFrame = subFrames[2]:addFrame():setSize("parent.w*0.5", "parent.h"):setPosition("parent.w*0.5"):setBackground(colors.yellow)

local dropdownPipes = pipesFrame:addDropdown():setSize("(parent.w-1)*0.5"):setBackground(colors.lightBlue)
local dropdownSides = pipesFrame:addDropdown():setSize("parent.w*0.5"):setPosition("parent.w*0.5",1)
    :addItem("top")
    :addItem("bottom")
    :addItem("left")
    :addItem("right")
    :addItem("front")
    :addItem("back")
local pipeList = pipesFrame:addList():setSize("parent.w","parent.h-3"):setPosition(1,2):setBackground(colors.blue)
local labelPeripheralName = pipesFrame:addLabel():setSize("parent.w",1):setPosition(1,"parent.h-1"):setBackground(colors.cyan):setText("")
local btnPlayPipe = pipesFrame:addButton():setSize("parent.w",1):setPosition(1,"parent.h"):setText("PLAY PIPE"):setBackground(colors.yellow)
local editConfig = configFrame:addTextfield():setSize("parent.w","parent.h-2"):setBackground(colors.black):setForeground(colors.white)
    :addRule("peripheralName=.+", colors.lightBlue)
    :addRule("pipe=.+", colors.yellow)
    :addRule("note=.+", colors.green)
local btnOrderByPipe = configFrame:addButton():setSize("parent.w*0.5",1):setPosition(1,"parent.h-1"):setText("Order Pipe"):setBackground(colors.purple)
local btnOrderbyNote = configFrame:addButton():setSize("parent.w*0.5",1):setPosition("parent.w*0.5+1", "parent.h-1"):setText("Order Note"):setBackground(colors.magenta)
local btnSaveConfig = configFrame:addButton():setSize("parent.w*0.5",1):setPosition(1,"parent.h"):setText("SAVE"):setBackground(colors.white)
local btnCreateVerify = configFrame:addButton():setSize("parent.w*0.5",1):setPosition("(parent.w+1)*0.5","parent.h"):setText("CREATE VERIFY"):setBackground(colors.lime)

local inputFrequency = subFrames[3]:addInput():setSize("parent.w*0.5",1):setDefaultText("Frequency:"):setInputLimit(5):setBackground(colors.blue)
local inputMaxDistance = subFrames[3]:addInput():setSize("parent.w*0.5",1):setPosition("parent.w*0.5"):setDefaultText("Max Distance:"):setInputLimit(3):setBackground(colors.lightBlue)
local btnOpenFrequency = subFrames[3]:addButton():setSize("parent.w*0.5",1):setPosition(1,2):setText("Open"):setBackground(colors.green)
local btnCloseFrequency = subFrames[3]:addButton():setSize("parent.w*0.5",1):setPosition("parent.w*0.5",2):setText("Close"):setBackground(colors.red)
local listMessages = subFrames[3]:addList():setSize("parent.w","parent.h-2"):setPosition(1,3):setBackground(colors.black):setForeground(colors.white)
local threadModem = subFrames[3]:addThread()

fillList(fs.find(organFilePath.."*"..fileEnd), fileList, true)
fillDropdown(dropdownPipes, confContent)
loadConfig(editConfig)
setOutputSide(dropdownSides, outputSide)

local function fileList_onChange(self, item)
    editField:clear()
    if item == nil then return end
    local data = loadFile(organFilePath..item.text..fileEnd)
    if data == nil then return end
    for i=1, #data do
        editField:addLine(data[i])
    end
end

local function pipeList_onChange(self, item)
    local itemName = item.text
    local dropdownName = dropdownPipes:getItem(dropdownPipes:getItemIndex()).text
    for i=1, #confContent do
        local currentContent = confContent[i]
        if currentContent.pipe == dropdownName and currentContent.note == itemName then
            labelPeripheralName:setText(currentContent.name)
        end
    end
end

local function dropdownPipes_onChange(self, item)
    pipeList:clear()
    for i=1, #confContent do
        if confContent[i].pipe:find(item.text) and confContent[i].pipe:len() == item.text:len() then
            pipeList:addItem(confContent[i].note)
        end
    end
    pipeList_onChange(pipeList, pipeList:getItem(pipeList:getItemIndex()))
end

local function listMessages_addMessage(message)
    listMessages:addItem(message)
end

local function handleModemMessages()
    local event, side, channel, replyChannel, message, distance
    repeat
        event, side, channel, replyChannel, message, distance = os.pullEvent("modem_message")
        
        if distance > maxDistance then
        elseif type(message) == "table" and connectedFrequency ~= nil then
            if message[1] == "PLAY" then
                local pipe = message[2]
                local note = message[3]
                local index = pipe.."_"..note

                if organ[index] == nil then
                    listMessages_addMessage("PLAY "..index.." NOT FOUND")
                else
                    organ[index](outputSide, not getOrgan[index](outputSide))
                    listMessages_addMessage("PLAY "..index)
                end
            elseif message[1] == "SEND" then
                local file = fs.open(".conf", "w")
                local recievedFile = message[2]

                for i=1, #recievedFile do
                    file.write(recievedFile[i].."\n")
                end
                file.close()

                organ = config.Check(peripheral.getNames())
                confContent = config.Check(peripheral.getNames(), 1)
                getOrgan = config.Check(peripheral.getNames(), 2)
                fillDropdown(dropdownPipes, confContent)
                loadConfig(editConfig)

                outputSide = message[3]
                local file = fs.open("startup.conf","w")
                file.write(outputSide)
                file.close()
                setOutputSide(dropdownSides, outputSide)
            end
        elseif message == "CONNECT" and connectedFrequency == nil then
            connectedFrequency = replyChannel
            modem.transmit(connectedFrequency, frequency, "CONNECTED TO "..frequency)
            listMessages_addMessage("CONNECTED TO "..connectedFrequency)
        elseif message == "DISCONNECT" and connectedFrequency ~= nil then
            listMessages_addMessage(connectedFrequency.." DISCONNECTED")
            connectedFrequency = nil
        elseif message == "RECIEVE" and connectedFrequency ~= nil then
            local file = fs.open(".conf", "r")
            local lines = {}
            while true do
                local line = file.readLine()
                if not line then break end
                
                lines[#lines+1] = line
            end
            modem.transmit(connectedFrequency, frequency, {lines,confContent,outputSide})
            listMessages_addMessage("SENDING CONFIG FILE")
        end
        os.sleep(0.5)
    until isOpen == false
end

-- Events
menubar:onChange(function (self, item)
    local id = self:getItemIndex()
    if subFrames[id] ~= nil then
        for i=1, #subFrames do subFrames[i]:hide() end
        subFrames[id]:show()
    end
end)

btnRegenerateConf:onClick(function ()
    if not fs.exists(".conf") then return end
    fs.delete(".conf")
    os.reboot()
end)

fileList:onChange(function (self, item)
    fileList_onChange(self, item)
end)

btnNew:onClick(function ()
    if #inputFileName:getValue() == 0 then return end
    local lastItem = fileList:getItem(fileList:getItemIndex())

    local file = fs.open(organFilePath..inputFileName:getValue()..fileEnd,"w")
    file.close()
    fillList(fs.find(organFilePath.."*"..fileEnd), fileList, false)

    if lastItem == nil then
        lastItem={text=organFilePath..inputFileName:getValue()..fileEnd}
    end

    local allEntries = fileList:getAll()
    for i=1, #allEntries do
        if allEntries[i].text == lastItem.text then
            fileList:selectItem(i)
            fileList_onChange(fileList,allEntries[i])
            break
        end
    end
    inputFileName:setValue("")
end)

btnDelete:onClick(function ()
    if fileList:getItemIndex() == nil then return end
    local fileName = organFilePath..fileList:getItem(fileList:getItemIndex()).text..fileEnd

    fs.delete(fileName)
    fillList(fs.find(organFilePath.."*"..fileEnd), fileList, false)
    fileList:selectItem(nil)
    fileList_onChange(fileList,nil)
end)

btnSaveFile:onClick(function ()
    if fileList:getItemIndex() == nil then return end
    local data = editField:getLines()
    local fileName = organFilePath..fileList:getItem(fileList:getItemIndex()).text..fileEnd
    local file = fs.open(fileName, "w")
    for i=1, #data do
        file.write(data[i].."\n")
    end
    file.close()
end)

btnPlay:onClick(function ()
    if fileList:getItemIndex() == nil then return end

    local filePath = fileList:getItem(fileList:getItemIndex()).text
    player.Play(organFilePath..filePath, organ, outputSide)
end)

dropdownPipes:onChange(function (self, item)
    dropdownPipes_onChange(self, item)
end)

dropdownSides:onChange(function (self, item)
    outputSide = item.text
    local file = fs.open("startup.conf","w")
    file.write(outputSide)
    file.close()
end)

pipeList:onChange(function (self, item)
    pipeList_onChange(self, item)
end)

btnPlayPipe:onClick(function ()
    if dropdownPipes:getItemIndex() == nil or pipeList:getItemIndex() == nil then return end
    local pipe = dropdownPipes:getItem(dropdownPipes:getItemIndex()).text
    local note = pipeList:getItem(pipeList:getItemIndex()).text
    organ[pipe.."_"..note](outputSide, not getOrgan[pipe.."_"..note](outputSide))
end)

btnOrderByPipe:onClick(function ()
    confContent = orderConfigByPipe(confContent)
    config.CreateConfWithConfContent(confContent)
    fillDropdown(dropdownPipes, confContent)
    loadConfig(editConfig)
end)

btnOrderbyNote:onClick(function ()
    confContent = orderConfigByNote(confContent)
    config.CreateConfWithConfContent(confContent)
    fillDropdown(dropdownPipes, confContent)
    loadConfig(editConfig)
end)

btnSaveConfig:onClick(function ()
    local data = editConfig:getLines()

    local file = fs.open(".conf", "w")
    for i=1, #data do
        file.write(data[i].."\n")
    end
    file.close()

    organ = config.Check(peripheral.getNames())
    confContent = config.Check(peripheral.getNames(), 1)
    getOrgan = config.Check(peripheral.getNames(), 2)
    fillDropdown(dropdownPipes, confContent)
    pipeList:clear()
end)

btnCreateVerify:onClick(function ()
    player.CreateVerificationFile(organFilePath.."verify"..fileEnd, 0.5, confContent)
    fillList(fs.find(organFilePath.."*"..fileEnd), fileList, true)
end)

btnOpenFrequency:onClick(function ()
    if #inputFrequency:getValue() == 0 or #inputMaxDistance:getValue() == 0 or isOpen == true then return end
    frequency = tonumber(inputFrequency:getValue())
    maxDistance = tonumber(inputMaxDistance:getValue())
    modem.open(frequency)
    listMessages_addMessage("Opened frequency "..frequency)
    isOpen = true
    threadModem:start(handleModemMessages)
end)

btnCloseFrequency:onClick(function ()
    if isOpen == false then return end
    modem.close(frequency)
    listMessages_addMessage("Closed frequency "..frequency)
    isOpen = false
    connectedFrequency = nil
    threadModem:stop()
end)

basalt.autoUpdate()