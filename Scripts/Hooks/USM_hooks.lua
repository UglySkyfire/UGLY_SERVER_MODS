-- Ugly Server Mods -- ideas an basic framework copied from DSMC (https://dsmcfordcs.wordpress.com/) 
-- HOOKS module

local ModuleName  	= "UGLY_ServerMods"
local MainVersion 	= "1"
local SubVersion 	= "0"
local Build 		= "0100"
local Date			= "23/01/2021"

-- ## LIBS	
module('HOOK', package.seeall)	-- module name. All function in this file, if used outside, should be called "HOOK.functionname"
base 						= _G	
require 					= base.require		
io 							= require('io')
lfs 						= require('lfs')
os 							= require('os')
USMdir						= lfs.writedir() .. "USM/"
DSOdir						= lfs.writedir()

package.path = 
	''
	..  USMdir..'?.lua;'
	..package.path

-- ## DEBUG TO TEXT FUNCTION
local debugProcess	= true -- this should be left on for testers normal ops and test missions

-- keep old USM.log file as "old"
local cur_debuglogfile  = io.open(lfs.writedir() .. "Logs/" .. "USM.log", "r")
local old_debuglogfile  = io.open(lfs.writedir() .. "Logs/" .. "USM_old.log", "w")
if cur_debuglogfile then
	old_debuglogfile:write(cur_debuglogfile:read("*a"))
	old_debuglogfile:close()
	cur_debuglogfile:close()
end	

-- set new USM.log file
local debuglogfile 	= io.open(lfs.writedir() .. "Logs/" .. "USM.log", "w")
debuglogfile:close()

function writeDebugBase(debuglog, othervar)
	if debuglog and debugProcess then
		local f = io.open(lfs.writedir() .. "Logs/" .. "USM.log", "r")		
		local oldDebug = f:read("*all")
		f:close()
		local newDebug = oldDebug .. "\n" .. os.date("%H:%M:%S") .. " - " .. debuglog
		local n = io.open(lfs.writedir() .. "Logs/" .. "USM.log", "w")		
		n:write(newDebug)
		if othervar then n:write("othervar exist\n") end
		n:close()
	end
end


function writeDebugDetail(debuglog, othervar)
	if debuglog and debugProcessDetail then
		local f = io.open(lfs.writedir() .. "Logs/" .. "USM.log", "r")		
		local oldDebug = f:read("*all")
		f:close()
		local newDebug = oldDebug .. "\n" .. os.date("%H:%M:%S") .. " - " .. debuglog
		local n = io.open(lfs.writedir() .. "Logs/" .. "USM.log", "w")		
		n:write(newDebug)
		if othervar then n:write("othervar exist\n") end
		n:close()
	end
end
writeDebugDetail(ModuleName .. ": local required and debug functions loaded")

--## MAIN VARIABLES
USM 						= {} -- main plugin table. Sim callback are here, while function is int the module (HOOK) 

writeDebugBase(ModuleName .. ": main variables loaded")

-- ## LOCAL VARIABLES
DCS_Multy					= nil
DCS_Server				= nil

USM_UseLiveMap		= true
USM_LiveMap				= nil

USM_UseAutoATIS		= false
USM_AutoATIS		  = nil

writeDebugDetail(ModuleName .. ": local variables loaded")

USM_ServerMode = true
if _G.panel_aircraft then
	USM_ServerMode = false
end

-- loading proper options from custom file (if dedicated server) or options menù (if standard)
function loadUSMHooks()
	if USM_ServerMode == true then
		writeDebugBase(ModuleName .. ": Server mode active")
		local dso_fcn, dso_err = dofile(USMdir .. "USM_Dedicated_Server_options.lua")
		if dso_err then
			writeDebugBase(ModuleName .. ": dso_fcn error = " .. tostring(dso_fcn))
			writeDebugBase(ModuleName .. ": dso_err error = " .. tostring(dso_err))
		end
	end

	-- ## USM CORE MODULES
	UTIL						= require("UTIL")
	writeDebugBase(ModuleName .. ": loaded UTIL module")

	-- ## USM LiveMap
	if UTIL.fileExist(USMdir .. "LiveMap" .. ".lua") == true and USM_UseLiveMap == true then
		USM_LiveMap	= require("LiveMap")

		if USM_LiveMap then
			writeDebugBase(ModuleName .. ": loaded LiveMap module")
		else
			writeDebugBase(ModuleName .. ": unable to load LiveMap module")
		end
	else
		if UTIL.fileExist(USMdir .. "LiveMap" .. ".lua") == false then
			writeDebugBase(ModuleName .. ": LiveMap does not exist")
		end
		if USM_UseLiveMap == false then
			writeDebugBase(ModuleName .. ": LiveMap should not be loaded")
		end
	end

	-- ## USM AutiATIS
	if UTIL.fileExist(USMdir .. "AutoATIS" .. ".lua") == true and USM_UseAutoATIS == true then
		USM_AutoATIS	= require("AutoATIS")

		if USM_AutoATIS then
			writeDebugBase(ModuleName .. ": loaded AutoATIS module")
		else
			writeDebugBase(ModuleName .. ": unable to load AutoATIS module")
		end
	else
		if UTIL.fileExist(USMdir .. "AutoATIS" .. ".lua") == false then
			writeDebugBase(ModuleName .. ": AutoATIS does not exist")
		end
		if USM_UseAutoATIS == false then
			writeDebugBase(ModuleName .. ": AutoATIS should not be loaded")
		end
	end

end

loadUSMHooks()


-- callback on start
function startUSMprocess()
	if UTIL then
		if USM_LiveMap then
			writeDebugBase(ModuleName .. ": activating LiveMap")
			USM_LiveMap.loadCode()
		elseif USM_AutoATIS then
			writeDebugBase(ModuleName .. ": activating AutoATIS")
			USM_AutoATIS.loadCode()
		end					
	else
		writeDebugBase(ModuleName .. ": ERROR: UTIL module not available")
	end
end

function ReportMissionLoadedToDiscord(message)
	local url = "https://discord.com/api/webhooks/834098193351442443/ytzUZ2tWcwA3F_NIs52bjpxiZMq1bO8Qa1ORjhb0tcH6S2ug4viSBca27PaOlW-G21A7"
	local botname = "Server Status Report"
	local text = 'C:\\temp\\DiscordSendWebhook.exe -m "Current Mission Loaded: **' .. message .. '**" -w "' .. url .. '" -n "' .. botname .. '"'
	
	writeDebugBase(ModuleName .. text)
	os.execute(text)
end

function ReportStatusToDiscord(message)
	local url = "https://discord.com/api/webhooks/834098193351442443/ytzUZ2tWcwA3F_NIs52bjpxiZMq1bO8Qa1ORjhb0tcH6S2ug4viSBca27PaOlW-G21A7"
	local botname = "Server Status Report"
	local text = 'C:\\temp\\DiscordSendWebhook.exe -m "**' .. message .. '**" -w "' .. url .. '" -n "' .. botname .. '"'
	
	writeDebugBase(ModuleName .. text)
	os.execute(text)
end

--## CALLBACKS
function USM.onSimulationStart()
	writeDebugBase(ModuleName .. ": Calling onSimulationStart...")
	startUSMprocess()
end

function USM.onMissionLoadEnd()
	writeDebugBase(ModuleName .. ": Calling onMissionLoadEnd..." .. DCS.getMissionName())
	ReportMissionLoadedToDiscord(DCS.getMissionName())
end

function USM.onTriggerMessage(message)	
	writeDebugBase(ModuleName .. ": Calling onTriggerMessage...")
end

function USM.onPlayerDisconnect()
	writeDebugBase(ModuleName .. ": Calling onPlayerDisconnect...")
end

function USM.onRadioMessage(message, duration)
	writeDebugBase(ModuleName .. ": Calling onRadioMessage...")
end

function USM.onShowGameMenu()
	writeDebugBase(ModuleName .. ": Calling onShowGameMenu...")
end

function USM.onSimulationStop()
	writeDebugBase(ModuleName .. ": Calling onSimulationStop...")
end

writeDebugBase(ModuleName .. ": callbacks loaded")

DCS.setUserCallbacks(USM)

writeDebugBase(ModuleName .. ": Loaded " .. MainVersion .. "." .. SubVersion .. "." .. Build .. ", released " .. Date)

--~=
