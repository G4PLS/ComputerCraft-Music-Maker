local ConfigHandler = require("config")
local OrganPlayer = require("player")

local outputSide = "top"
local organ = ConfigHandler.Check(peripheral.getNames())
local conf = ConfigHandler.Check(peripheral.getNames(), true)

print(#conf)
--OrganPlayer.CreateVerificationFile("verify", 0.5, conf)

OrganPlayer.Play("verify.org", organ, outputSide)