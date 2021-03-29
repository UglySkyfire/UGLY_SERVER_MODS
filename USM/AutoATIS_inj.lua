-- Ugly Server Mods - Live Map injected module

local ModuleName  	= "AutoATIS"
local MainVersion 	= "1"
local SubVersion 	= "0"
local Build 		= "0100"
local Date			= "23/01/2021"

--## MAIN TABLE
AutoATIS             = {}

--## LOCAL VARIABLES
local base 		    = _G
local USM_io 	    = base.io  	-- check if io is available in mission environment
local USM_lfs 	    = base.lfs		-- check if lfs is available in mission environment

-- The intervall in which the live map JSON data is exported

-----------------------------------------------------------------------------------------
-- Temp - Must be loaded from file/injected

AutoATIS.AtisConf = {}
AutoATIS.AtisConf["Batumi"] = {}
AutoATIS.AtisConf["Batumi"]["ATISFreq"] = 260.15
AutoATIS.AtisConf["Batumi"]["TowerFreqA"] = 260.100
AutoATIS.AtisConf["Batumi"]["TowerFreqB"] = 131.100
AutoATIS.AtisConf["Batumi"]["Tacan"] = 16
AutoATIS.AtisConf["Senaki-Kolkhi"] = {}
AutoATIS.AtisConf["Senaki-Kolkhi"]["ATISFreq"] = 251.150
AutoATIS.AtisConf["Senaki-Kolkhi"]["TowerFreqA"] = 251.100
AutoATIS.AtisConf["Senaki-Kolkhi"]["TowerFreqB"] = 121.900
AutoATIS.AtisConf["Senaki-Kolkhi"]["Tacan"] = 31
AutoATIS.AtisConf["Kutaisi"] = {}
AutoATIS.AtisConf["Kutaisi"]["ATISFreq"] = 270.650
AutoATIS.AtisConf["Kutaisi"]["TowerFreqA"] = 270.600
AutoATIS.AtisConf["Kutaisi"]["TowerFreqB"] = 125.500
AutoATIS.AtisConf["Kutaisi"]["Tacan"] = 44

-----------------------------------------------------------------------------------------
-- Configuration

local coalitions = {}
coalitions[1] = coalition.side.RED
coalitions[2] = coalition.side.BLUE
--coalitions[3] = coalition.side.NEUTRAL
	

local atisUnits = {}
atisUnits[1] = {}
atisUnits[1]["type"] = "Ka-27" -- Red ATIS unit
atisUnits[1]["CountryID"] = 0 -- Red ATIS country

atisUnits[2] = {}
atisUnits[2]["type"] = "UH-1H" -- Blue ATIS unit
atisUnits[2]["CountryID"] = 2 -- Blue ATIS country

-----------------------------------------------------------------------------------------
-- Main code

-- add atis to airport
AutoATIS.AddAtis = function (_name, _atisConf)  
    local newAtis=ATIS:New(_name, _atisConf["ATISFreq"])
    newAtis:SetRadioRelayUnitName("ATIS " .. _name)
    newAtis:SetTowerFrequencies({_atisConf["TowerFreqA"], _atisConf["TowerFreqB"]})
    newAtis:SetImperialUnits()
    newAtis:SetTACAN(_atisConf["Tacan"])
    newAtis:Start()
end

-- place unit at predefined position depended of coalition
AutoATIS.createAtisObjectForAirbase = function (_name, _coalition)
    local configName = "ATIS " .. _name
    local _conf = UglyAtisStatics[configName]

    if _conf ~= nil then
        local tmpGrp = {}
        tmpGrp["visible"] = true
        tmpGrp["x"] = _conf["x"]
        tmpGrp["y"] = _conf["y"]
        tmpGrp["CountryID"] = atisUnits[_coalition]["CountryID"]
        tmpGrp["CategoryID"] = 1 -- heli hardcoded
        tmpGrp["name"] = _conf["name"]
        tmpGrp["CoalitionID"] = _coalition
        tmpGrp["uncontrolled"] = true
        tmpGrp["tasks"] = {}
        tmpGrp["task"] = "transport"
        tmpGrp["units"] = {}
        tmpGrp["units"][1] = {}
        tmpGrp["units"][1]["x"] = _conf["x"]
        tmpGrp["units"][1]["y"] = _conf["y"]
        tmpGrp["units"][1]["type"] = atisUnits[_coalition]["type"]
        tmpGrp["units"][1]["name"] = _conf["name"]
        tmpGrp["units"][1]["shape_name"] = atisUnits[_coalition]["type"]
        tmpGrp["units"][1]["heading"] = _conf["heading"]
        --  
        coalition.addGroup(tmpGrp["CountryID"], tmpGrp["CategoryID"], tmpGrp)
        env.info("UGLY: Adding group as ATIS to: " .. tostring(_coalition))
    end
end

AutoATIS.injectAtisToMap = function (_atisPosConfigFile)
    if UglyAtisStatics ~= nil then -- Data has been injected properly
        env.info("UGLY: Existing database, using given atis conf.")

        for k = 1, #coalitions do
            local tmp = coalition.getAirbases(coalitions[k])
            for i=1, #tmp do
                env.info("UGLY: Adding objects to coalition: " .. coalitions[k])

                if AutoATIS.AtisConf[tmp[i]:getName()] ~= nil then
                    env.info("UGLY: Adding object to airfield: " .. tmp[i]:getName())

                    local GroupObject = GROUP:FindByName( tmp[i]:getName() )
                    if GroupObject == nil then
                        AutoATIS.createAtisObjectForAirbase(tmp[i]:getName(), coalitions[k])
                    else
                        env.info("UGLY: Group exists - reusing: " .. tmp[i]:getName())
                    end
                   
                    AutoATIS.AddAtis(tmp[i]:getName(), AutoATIS.AtisConf[tmp[i]:getName()])
                end
            end
        end
    else
        env.info("Atis data not injected")
    end
end  
  
local frameNumber = 0
AutoATIS.startMapAfterMoose = function (argument, time)

    trigger.action.outText("Wait for Moose...", 2)

    if ENUMS == nil then
        trigger.action.outText("Wating for Moose to be loaded!", 3)
    else
        trigger.action.outText("Moose is loaded - Starting AutoATIS", 5)
        env.info("Moose is loaded - Starting AutoATIS")
        AutoATIS.injectAtisToMap(atisPosConfigFile)

        return 0
    end

    trigger.action.outText("debugTestPrint framenumber: "..frameNumber, 3)

    frameNumber = frameNumber + 1

    return time + 5
end




timer.scheduleFunction(AutoATIS.startMapAfterMoose, {}, timer.getTime() + 30)


-----------------------------------------------------------------------------------------
-- Leftovers

--[[
if env.mission.theatre == "Caucasus" then
    local tTbl = {}
    for tName, tData in pairs(CaucasusTowns) do
        tTbl[#tTbl+1] = tData
    end
    AutoATIS.TerrainDb["towns"] = tTbl
    CaucasusTowns = nil
elseif env.mission.theatre == "Nevada" then
    local tTbl = {}
    for tName, tData in pairs(NevadaTowns) do
        tTbl[#tTbl+1] = tData
    end
    AutoATIS.TerrainDb["towns"] = tTbl
    NevadaTowns = nil
elseif env.mission.theatre == "Normandy" then
    local tTbl = {}
    for tName, tData in pairs(NormandyTowns) do
        tTbl[#tTbl+1] = tData
    end
    AutoATIS.TerrainDb["towns"] = tTbl
    NormandyTowns = nil
elseif env.mission.theatre == "PersianGulf" then
    local tTbl = {}
    for tName, tData in pairs(PersianGulfTowns) do
        tTbl[#tTbl+1] = tData
    end
    AutoATIS.TerrainDb["towns"] = tTbl
    PersianGulfTowns = nil
elseif env.mission.theatre == "TheChannel" then
    local tTbl = {}
    for tName, tData in pairs(TheChannelTowns) do
        tTbl[#tTbl+1] = tData
    end
    AutoATIS.TerrainDb["towns"] = tTbl
    TheChannelTowns = nil
elseif env.mission.theatre == "Syria" then
    local tTbl = {}
    for tName, tData in pairs(SyriaTowns) do
        tTbl[#tTbl+1] = tData
    end
    AutoATIS.TerrainDb["towns"] = tTbl
    SyriaTowns = nil
else
    env.error(("AutoATIS, no theater identified: halting everything"))
    return
end
]]--

