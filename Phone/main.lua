local basalt = require("basalt")

local modem = peripheral.find("modem")

local frequency = 65535
local connectedFrequency = 1
local isConnected = false

local configFile = {}
local confContent = {}
local outputSide = ""

local mainFrame = basalt.createFrame()

-- UI DEFINITION
local menubar = mainFrame:addMenubar():setSize("parent.w"):setBackground(colors.gray):setForeground(colors.lightGray)
    :addItem("Connection")
    :addItem("Edit")

local subFrames = {
    mainFrame:addFrame():setPosition(1,2):setSize("parent.w", "parent.h-1"),
    mainFrame:addFrame():setPosition(1,2):setSize("parent.w", "parent.h-1"):hide()
}

local inputFrequency = subFrames[1]:addInput():setSize("parent.w",1):setDefaultText("Organ Frequency:"):setBackground(colors.blue)
local btnConnect = subFrames[1]:addButton():setSize("parent.w*0.5",1):setPosition(1,2):setText("Connect"):setBackground(colors.green)
local btnDisconnect = subFrames[1]:addButton():setSize("parent.w*0.5",1):setPosition("parent.w*0.5+1",2):setText("Disconnect"):setBackground(colors.red)
local btnRecieve = subFrames[1]:addButton():setSize("parent.w*0.5",1):setPosition(1,3):setText("Recieve"):setBackground(colors.white)
local btnSend = subFrames[1]:addButton():setSize("parent.w*0.5",1):setPosition("parent.w*0.5+1",3):setText("Send"):setBackground(colors.yellow)
local listMessages = subFrames[1]:addList():setSize("parent.w", "parent.h-3"):setPosition(1,4):setBackground(colors.black):setForeground(colors.white)

local pipesFrame = subFrames[2]:addFrame():setSize("parent.w","(parent.h-2)*0.5"):setBackground(colors.green)
local configFrame = subFrames[2]:addFrame():setSize("parent.w", "parent.h*0.5+1"):setPosition(1,"parent.h*0.5"):setBackground(colors.yellow)

local dropdownPipes = pipesFrame:addDropdown():setSize("parent.w*0.5-1"):setBackground(colors.lightBlue)
local dropdownSides = pipesFrame:addDropdown():setSize("parent.w*0.5"):setPosition("parent.w*0.5",1)
    :addItem("top")
    :addItem("bottom")
    :addItem("left")
    :addItem("right")
    :addItem("front")
    :addItem("back")

local pipeList = pipesFrame:addList():setSize("parent.w","parent.h-2"):setPosition(1,2):setBackground(colors.blue)
local labelPeripheralName = pipesFrame:addLabel():setSize("parent.w",1):setPosition(1,"parent.h"):setBackground(colors.cyan):setText("")

local editConfig = configFrame:addTextfield():setSize("parent.w","parent.h-2"):setBackground(colors.black):setForeground(colors.white)
    :addRule("peripheralName=.+", colors.lightBlue)
    :addRule("pipe=.+", colors.yellow)
    :addRule("note=.+", colors.green)
local btnOrderByPipe = configFrame:addButton():setSize("parent.w*0.5",1):setPosition(1,"parent.h-1"):setText("Order Pipe"):setBackground(colors.purple)
local btnOrderbyNote = configFrame:addButton():setSize("parent.w*0.5",1):setPosition("parent.w*0.5+1", "parent.h-1"):setText("Order Note"):setBackground(colors.magenta)
local btnSaveConfig = configFrame:addButton():setSize("parent.w*0.5",1):setPosition(1,"parent.h"):setText("SAVE"):setBackground(colors.white)
local btnPlayPipe = configFrame:addButton():setSize("parent.w*0.5",1):setPosition("parent.w*0.5+1","parent.h"):setText("PLAY PIPE"):setBackground(colors.yellow)

function fillDropdownPipes(dropdown)
    dropdown:clear()
    local dropCount = {}
    for i=1, #confContent do
        if dropCount[confContent[i].pipe] == nil then
            dropdown:addItem(confContent[i].pipe)
            dropCount[confContent[i].pipe]=1
        end
    end
end

function setOutputSide(dropdown, outputSide)
    local data = dropdown:getAll()

    for i=1, #data do
        if data[i].text == outputSide then
            dropdown:selectItem(i)
            break
        end
    end
end

function pipeList_onChange(self, item)
    local itemName = item.text
    local dropdownName = dropdownPipes:getItem(dropdownPipes:getItemIndex()).text
    for i=1, #confContent do
        local currentContent = confContent[i]
        if currentContent.pipe == dropdownName and currentContent.note == itemName then
            labelPeripheralName:setText(currentContent.name)
        end
    end
end

function dropdownPipes_onChange(self, item)
    pipeList:clear()
    for i=1, #confContent do
        if confContent[i].pipe:find(item.text) and confContent[i].pipe:len() == item.text:len() then
            pipeList:addItem(confContent[i].note)
        end
    end
    pipeList_onChange(pipeList, pipeList:getItem(pipeList:getItemIndex()))
end

function createConfFile()
    local file = fs.open(".conf", "w")
    for i=1, #configFile do
        file.write(configFile[i].."\n")
    end
    file.close()
end

function loadConfig()
    editConfig:clear()
    local file = fs.open(".conf", "r")

    while true do
        local line = file.readLine()
        if not line then break end
        editConfig:addLine(line)
    end
end

function createConfContent()
    function GetCharToEnd(string, char)
        local _, fin = string:find(char)
        return string:sub(fin + 1, string:len())
    end
    local configContent = {}
    local file = fs.open(".conf", "r")

    local creatingObject = false
    local currentObject = { peripheral = nil, note = "", pipe = "", name = ""}

    -- Reads the Config file and creates a table with Objects that represent the Pipes
    while true do
        local line = file.readLine()
        if not line then break end

        if line:find("{") and creatingObject == false then
            creatingObject = true
        elseif line:find("}") and creatingObject == true then
            configContent[#configContent+1] = currentObject
            currentObject = { peripheral=nil, note="", pipe="", name=""}
            creatingObject = false
        elseif line:find("peripheralName") then
            local name = GetCharToEnd(line, "=")
            currentObject.peripheral = peripheral.wrap(name)
            currentObject.name = name
        elseif line:find("pipe") then
            currentObject.pipe = GetCharToEnd(line, "=")
        elseif line:find("note") then
            currentObject.note = GetCharToEnd(line, "=")
        end
    end

    confContent = configContent
end

function saveSortedConfig()
    local file = fs.open(".conf", "w")
    for i=1, #confContent do
        local field = string.format([[
{
 peripheralName=%s
 pipe=%s
 note=%s
}%s
]], confContent[i].name, confContent[i].pipe, confContent[i].note, i < #confContent and "," or "")
    file.write(field)
    end
    file.close()
end

menubar:onChange(function (self, item)
    local id = self:getItemIndex()
    if subFrames[id] ~= nil then
        for i=1, #subFrames do subFrames[i]:hide() end
        subFrames[id]:show()
    end
end)

btnConnect:onClick(function ()
    if isConnected then return end

    if #inputFrequency:getValue() == 0 then return end
    connectedFrequency = tonumber(inputFrequency:getValue())

    modem.open(frequency)
    modem.transmit(connectedFrequency, frequency, "CONNECT")

    local timeout = os.startTimer(3)
    while true do
        local event = {os.pullEvent()}
        if event[1]=="modem_message" then
            listMessages:addItem("Conencted to "..connectedFrequency)
            isConnected = true
            break
        elseif event[1] == "timer" and event[2]  == timeout then
            listMessages:addItem("Connection to "..connectedFrequency.." failed")
            modem.close(frequency)
            break
        end
    end
end)

btnDisconnect:onClick(function ()
    if isConnected ~= true then return end 
    modem.transmit(connectedFrequency, frequency, "DISCONNECT")

    modem.close(15)
    isConnected = false
    listMessages:addItem("Disconnected from "..connectedFrequency)
    
end)

btnRecieve:onClick(function ()
    if isConnected ~= true then return end

    modem.transmit(connectedFrequency, frequency, "RECIEVE")

    local timeout = os.startTimer(3)
    while true do
        local event = {os.pullEvent()}
        if event[1]=="modem_message" then
            configFile = event[5][1]
            confContent = event[5][2]
            outputSide = event[5][3]
            fillDropdownPipes(dropdownPipes)
            setOutputSide(dropdownSides, outputSide)
            createConfFile()
            loadConfig()
            listMessages:addItem("RECIEVED CONFIG FILE")
            break
        elseif event[1] == "timer" and event[2]  == timeout then
            listMessages:addItem("DIDNT RECIEVE CONFIG FILE")
            break
        end
    end
end)

btnSend:onClick(function ()
    if isConnected ~= true then return end

    local file = fs.open(".conf", "r")
    local lines = {}
    while true do
        local line = file.readLine()
        if not line then break end
        lines[#lines+1] = line
    end

    modem.transmit(connectedFrequency, frequency, {"SEND", lines, outputSide})
end)

dropdownPipes:onChange(function (self, item)
    dropdownPipes_onChange(self,item)
end)

dropdownSides:onChange(function (self, item)
    outputSide = item.text
end)

pipeList:onChange(function (self, item)
    pipeList_onChange(self, item)
end)

btnOrderByPipe:onClick(function ()
    table.sort(confContent, function (a, b)
        return a.pipe < b.pipe
    end)

    saveSortedConfig()

    loadConfig()
end)

btnOrderbyNote:onClick(function ()
    table.sort(confContent, function (a, b)
        return a.note < b.note
    end)

    saveSortedConfig()

    loadConfig()
    createConfContent()
    fillDropdownPipes(dropdownPipes)
end)

btnSaveConfig:onClick(function ()
    local data = editConfig:getLines()

    local file = fs.open(".conf", "w")
    for i=1, #data do
        file.write(data[i].."\n")
    end
    file.close()

    createConfContent()
    fillDropdownPipes(dropdownPipes)
    pipeList:clear()
end)

btnPlayPipe:onClick(function ()
    if isConnected ~= true then return end
    local pipe = dropdownPipes:getItem(dropdownPipes:getItemIndex())
    local note = pipeList:getItem(pipeList:getItemIndex())

    if pipe == nil or note == nil then return end

    modem.transmit(connectedFrequency, frequency, {"PLAY", pipe.text, note.text})
end)

basalt.autoUpdate()