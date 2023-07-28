local Config = { confContent = {} }

local function GetCharToEnd(string, char)
    local _, fin = string:find(char)
    return string:sub(fin + 1, string:len())
end

local function Create(peripheralNames)
    local file = fs.open(".conf", "w")

    for i, val in pairs(peripheralNames) do
        if peripheral.getType(val) == "redstoneIntegrator" then
            local field = string.format([[
{
 peripheralName=%s
 pipe=
 note=
}%s
]], val, i < #peripheralNames and "," or "")
            file.write(field)
        end
    end
    file.close()
end

local function Load(outputConfigContent)
    local configContent = {}
    local file = fs.open(".conf", "r")

    local creatingObject = false
    local currentObject = { peripheral = nil, note = "", pipe = "", name = ""}

    -- Reads the Config file and creates a table with Objects that represent the Pipes
    while true do
        local line = file.readLine()
        if not line then break end

        if line:find("{") then
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

    if outputConfigContent then return configContent end

    local out = {}

    -- Uses the configContent table to fill the output table with the functions to play the note
    for i=1, #configContent do
        local index = configContent[i].pipe.."_"..configContent[i].note

        if out[index] == nil then
            out[index] = configContent[i].peripheral.setOutput
        else
            print("Note Already Set! "..index)
        end
    end

    return out
end

function Config.Check(peripheralNames, out)
    if not fs.exists(".conf") then
        Create(peripheralNames)
    end
    return Load(out)
end

return Config