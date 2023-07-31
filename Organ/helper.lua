function getFilesFromDir(dirPath)
    return fs.find(dirPath)
end

function loadFile(filePath)
    if fs.exists(filePath) then
        local file = fs.open(filePath, "r")
        local lines = {}
        while true do
            local line = file.readLine()
            if not line then break end
            lines[#lines+1]=line
        end
        file.close()
        return lines
    end
    return nil
end

function fillList(table, list, unselect)
    unselect = unselect or false
    list:clear()
    for i=1, #table do
        local path = table[i]:find("/")
        local dot = table[i]:find(".org")
        local file = table[i]:sub(path+1,dot-1)
        list:addItem(file)
    end
    if unselect then list:selectItem(nil) end
end

function fillDropdown(dropdown, confContent)
    dropdown:clear()
    local dropCount = {}
    for i=1, #confContent do
        if dropCount[confContent[i].pipe] == nil then
            dropdown:addItem(confContent[i].pipe)
            dropCount[confContent[i].pipe]=1
        end
    end
end

function loadConfig(textField)
    textField:clear()
    local file = fs.open(".conf", "r")

    while true do
        local line = file.readLine()
        if not line then break end
        textField:addLine(line)
    end
end

function loadStartupFile(outputSide)
    if fs.exists("startup.conf") then
        local file = fs.open("startup.conf", "r")
        outputSide = file.readLine()
        file.close()
        return outputSide
    else
        local file = fs.open("startup.conf", "w")
        file.write(outputSide)
        file.close()
        return outputSide
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

function orderConfigByPipe(confContent)
    table.sort(confContent, function (a, b)
        return a.pipe < b.pipe
    end)
    return confContent
end

function orderConfigByNote(confContent)
    table.sort(confContent, function (a, b)
        return a.note < b.note
    end)
    return confContent
end