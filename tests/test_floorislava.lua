package.path = "./tests/?.lua;" .. package.path
local M = require("mock_wow")
M.install()
Enum = { DamageMeterType = { AvoidableDamageTaken = 8, Deaths = 9 }, DamageMeterSessionType = { Overall = 0, Current = 1, Expired = 2 } }
RAID_CLASS_COLORS = { MAGE = { colorStr = "ff3fc7eb" } }
local sessions = {}
C_DamageMeter = {
  IsDamageMeterAvailable = function() return true, "" end,
  GetAvailableCombatSessions = function() local l = {} for id in pairs(sessions) do l[#l + 1] = { sessionID = id, name = "x" } end return l end,
  GetCombatSessionFromID = function(id, t) return sessions[id] and sessions[id][t] or { combatSources = {} } end,
  GetCombatSessionFromType = function() return { combatSources = {} } end,
}
-- Details mock
local registered, installed, shown = {}, nil, false
Details = { realversion = 172, ToolBar = {} }
Details.__index = Details
function Details:NewPluginObject(name) return setmetatable({ Frame = CreateFrame("Frame", name) }, Details) end
function Details:InstallPlugin(ptype, name, icon, obj, abs, minV) installed = { ptype, name, abs, minV } return true, {}, true end
function Details:RegisterEvent(plugin, e) registered[e] = plugin end
function Details:ShowToolbarIcon() shown = true end
function Details.ToolBar:NewPluginToolbarButton(func) return { click = func } end
DETAILSPLUGIN_ALWAYSENABLED = 1

local ns = M.loadAddon(".", "FloorIsLava")
M.fire("PLAYER_LOGIN"); M.advance(1)
M.check(installed and installed[1] == "TOOLBAR" and installed[4] == 172, "Details TOOLBAR plugin installed, min version pinned")
M.check(shown and ns.plugin.ToolbarButton, "toolbar button shown")
M.check(registered.COMBAT_PLAYER_LEAVE == ns.plugin, "COMBAT_PLAYER_LEAVE registered")

local secretName = {}; M.secret[secretName] = true
sessions[3] = {
  [8] = { combatSources = {
    { name = "Kenny", classFilename = "WARRIOR", totalAmount = 1200, isLocalPlayer = true },
    { name = "Jaina", classFilename = "MAGE", totalAmount = 45000 },
    { name = secretName, classFilename = "ROGUE", totalAmount = 99999 },
    { name = "Zero", classFilename = "PRIEST", totalAmount = 0 } } },
  [9] = { combatSources = { { name = "Jaina", totalAmount = 1 } } },
}
sessions[2] = { [8] = { combatSources = { { name = "Old", totalAmount = 1e9 } } } }
local rows = ns.Lava.Scan()
M.check(#rows == 2 and rows[1].name == "Jaina" and rows[1].deaths == 1, "latest session, secrets and zeros skipped, deaths joined")
-- solo fights are ignored by default
ns.plugin:OnDetailsEvent("COMBAT_PLAYER_LEAVE"); M.advance(2)
M.check(ns.Lava.db.last == nil, "solo fight ignored by default")
M.group.inGroup = true
ns.plugin:OnDetailsEvent("COMBAT_PLAYER_LEAVE")
M.fire("PLAYER_REGEN_ENABLED") -- both paths in the same second -> one scan
M.advance(2)
M.check(ns.Lava.db.tally.Jaina == 1, "one champion per fight")
M.check(M.printed("champion: Jaina with 45.0k"), "local champion line")
M.check(#M.chat == 0, "nothing sent to chat by itself")
-- no scan while in combat
M.combat = true; M.fire("PLAYER_REGEN_ENABLED"); M.advance(2); M.combat = false
M.check(ns.Lava.db.tally.Jaina == 1, "no scan in combat")
-- report is user-typed and respects lockdown
M.lockdown = true; M.slash("/lava", "report"); M.check(#M.chat == 0, "no report during lockdown")
M.lockdown = false; M.slash("/lava", "report")
M.check(#M.chat == 1 and M.chat[1][1]:find("1%. Jaina 45%.0k") and M.chat[1][2] == "PARTY", "report posts top 3")
-- board
M.slash("/lava", "")
M.check(FloorIsLavaBoard and FloorIsLavaBoard:IsShown(), "board opens")
-- old Details is not touched
ns.plugin = nil; Details.realversion = 150; installed = nil
M.check(ns.InstallDetails() == false and installed == nil, "older Details skipped")
-- meter unavailable
C_DamageMeter.IsDamageMeterAvailable = function() return false, "disabled" end
local r, why = ns.Lava.Scan()
M.check(r == nil and why == "disabled", "unavailable meter reported")
M.check(ns.Lava.Short(1234567) == "1.2m" and ns.Lava.Short(999) == "999", "number format")
M.done("FloorIsLava")
