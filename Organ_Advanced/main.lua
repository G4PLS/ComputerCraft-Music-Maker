local basalt = require("basalt")
local ConfigManager = require("config")
local Organ = require("player")

local outputSide = "top"
local organ = ConfigManager.Check(peripheral.getNames())
local confContent = ConfigManager.Check(peripheral.getNames(), true)

function loadFiles(list)
    list:clear()
    local files =  fs.find("*.org")
    for i=1, #files do
        local beg  = files[i]:find(".", 1, true)
        local name = files[i]:sub(1,beg-1)
        list:addItem(name)
    end
end


local main = basalt.createFrame():setTheme({FrameBG=colors.lightGray, FrameFG=colors.black})
local mainW, mainH = main:getSize()

local menubar = main:addMenubar():setSize(mainW):setForeground(colors.lightGray)
menubar:addItem("Organ", colors.gray)
menubar:addItem("Pipes", colors.gray)

local sub = {
    main:addFrame():setPosition(1,2):setSize(mainW, mainH - 1),
    main:addFrame():setPosition(1,2):setSize(mainW, mainH - 1):hide()
}

-- REMOVE DO END IN THE END
-- UI CODE FOR sub[1] (Organ Section)
do
local percentile = 0.65
local fileFrame = sub[1]:addFrame():setSize(math.ceil(mainW*(1-percentile)),mainH-1):setBackground(colors.yellow)
local editFrame = sub[1]:addFrame()
:setSize(mainW*percentile,mainH-1)
:setPosition(math.ceil((mainW+2)*(1-percentile)),1)
:setBackground(colors.black)

local fileList = fileFrame:addList()
:setSize(math.ceil(mainW*(1-percentile)),mainH-3)
loadFiles(fileList)
fileList:selectItem(0)

local btnNew = fileFrame:addButton()
:setText("New")
:setSize(math.ceil(mainW*(1-percentile)) * 0.5, 1)
:setPosition(1, mainH-2)
:setBackground(colors.white)

local inputName = fileFrame:addInput()
:setSize(math.ceil(mainW*(1-percentile)) * 0.5, 1)
:setPosition(10, mainH-2)
:setInputLimit(25)
:setDefaultText("File Name")

local btnDelete = fileFrame:addButton()
:setText("Delete")
:setSize(math.ceil(mainW*(1-percentile)), 1)
:setPosition(1, mainH-1)
:setBackground(colors.red)

local editField = editFrame:addTextfield()
:setSize(mainW*percentile, mainH-2)
--/%*(.-)%*/
editField:addRule("%d", colors.lightBlue)
editField:addKeywords(colors.red, {"note"})

local btnSave = editFrame:addButton()
:setPosition(1,mainH-1)
:setSize(20,1)
:setText("Save")
:setBackground(colors.lime)

local btnPlay = editFrame:addButton()
:setPosition(btnSave:getWidth()+2, mainH-1)
:setSize(10,1)
:setText("Play")
:setBackground(colors.white)

fileList:onSelect(function (self, event, item)
    editField:clear()
    if not fs.exists(item.text..".org") then return end

    local file = fs.open(item.text..".org", "r")
    
    while true do
        local line = file.readLine()
        if not line then break end
        editField:addLine(line)
    end
    file.close()
end)

btnSave:onClick(function ()
    if fileList:getItemIndex() == nil then return end
    local data = editField:getLines()
    local fileName = fileList:getItem(fileList:getItemIndex()).text..".org"
    
    local file = fs.open(fileName, "w")
    for i=1, #data do
        file.write(data[i].."\n")
    end
    file.close()
end)

btnNew:onClick(function ()
    local file = fs.open(inputName:getValue()..".org", "w")
    file.close()
    loadFiles(fileList)
    inputName:setValue("")
end)

btnDelete:onClick(function ()
    if fileList:getItemIndex() == nil then return end
    local fileName = fileList:getItem(fileList:getItemIndex()).text..".org"
    fs.delete(fileName)
    loadFiles(fileList)
end)

btnPlay:onClick(function()
    if fileList:getItemIndex() == nil then return end

    local filePath = fileList:getItem(fileList:getItemIndex()).text..".org"
    --Organ.Play(filePath, organ, outputSide)
    Organ.Play(filePath, organ, outputSide)
end)
end

--REMOVE DO END IN THE END
-- ZU CODE FOR sub[2] (Pipe Section)
local percentile = 0.65
local pipeFrame = sub[2]:addFrame():setSize(math.ceil(mainW*(1-percentile)),mainH-1):setBackground(colors.yellow)
local configFrame = sub[2]:addFrame()
:setSize(mainW*percentile,mainH-1)
:setPosition(math.ceil((mainW+2)*(1-percentile)),1)
:setBackground(colors.black)

-- SADLY NOT WORKING
local treeView = pipeFrame:addTreeview():setSize(50,20):setForeground(colors.orange):setBackground(colors.black)

menubar:onChange(function (self)
    local id = self:getItemIndex()

    if sub[id] ~= nil then
        for i=1, #sub do
            sub[i]:hide()
        end
        sub[id]:show()
    end
end)

basalt.autoUpdate()