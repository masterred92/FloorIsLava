-- Floor is Lava: after each fight, crowns whoever took the most avoidable damage. All numbers come from the game's
-- own damage meter (C_DamageMeter, AvoidableDamageTaken and Deaths), read only after combat and never while values
-- are secret. Nothing is sent to anyone unless you type /lava report.
local addonName, ns = ...

local Lava = {}
ns.Lava = Lava
FloorIsLava = Lava

local defaults = { announceLocal = true, groupOnly = true, minAmount = 1, tally = {}, last = nil }
local db

local function say(msg) print("|cffff6a00Floor is Lava|r: " .. msg) end
Lava.say = say
local secret = ns.Compat.IsSecret -- shared helper (KennyShared)

function Lava.Short(n)
  if n >= 1e6 then return ("%.1fm"):format(n / 1e6) elseif n >= 1e3 then return ("%.1fk"):format(n / 1e3) end
  return tostring(math.floor(n))
end

local function latestSessionID()
  local ok, list = pcall(C_DamageMeter.GetAvailableCombatSessions)
  if not ok or type(list) ~= "table" then return nil end
  local best
  for _, s in ipairs(list) do if type(s.sessionID) == "number" and (not best or s.sessionID > best) then best = s.sessionID end end
  return best
end

local function getSession(meterType, sessionID)
  local ok, session
  if sessionID then ok, session = pcall(C_DamageMeter.GetCombatSessionFromID, sessionID, meterType)
  else ok, session = pcall(C_DamageMeter.GetCombatSessionFromType, Enum.DamageMeterSessionType.Current, meterType) end
  if ok and type(session) == "table" and type(session.combatSources) == "table" then return session end
end

-- Returns the sorted board for the last fight, or nil + reason.
function Lava.Scan()
  if type(C_DamageMeter) ~= "table" then return nil, "no damage meter in this client" end
  local okA, available, why = pcall(C_DamageMeter.IsDamageMeterAvailable)
  if not okA or not available then return nil, (type(why) == "string" and why ~= "" and why) or "damage meter unavailable" end
  local id = latestSessionID()
  local avoid = getSession(Enum.DamageMeterType.AvoidableDamageTaken, id)
  if not avoid then return nil, "no fight recorded yet" end
  local deaths = {}
  local d = getSession(Enum.DamageMeterType.Deaths, id)
  if d then
    for _, src in ipairs(d.combatSources) do
      if not secret(src.name) and type(src.name) == "string" and not secret(src.totalAmount) then
        deaths[src.name] = tonumber(src.totalAmount) or 0
      end
    end
  end
  local rows = {}
  for _, src in ipairs(avoid.combatSources) do
    local name, amount = src.name, src.totalAmount
    if not secret(name) and not secret(amount) and type(name) == "string" and type(amount) == "number" and amount > 0 then
      rows[#rows + 1] = { name = name, class = src.classFilename, amount = amount, deaths = deaths[name] or 0, me = src.isLocalPlayer }
    end
  end
  table.sort(rows, function(a, b) if a.amount ~= b.amount then return a.amount > b.amount end return a.name < b.name end)
  return rows
end

function Lava.AfterCombat()
  if not db then return end
  if db.groupOnly and not IsInGroup() then return end
  local rows = Lava.Scan()
  if not rows or not rows[1] or rows[1].amount < db.minAmount then return end
  db.last = { at = time(), rows = {} }
  for i = 1, math.min(#rows, 10) do db.last.rows[i] = rows[i] end
  local champ = rows[1]
  db.tally[champ.name] = (db.tally[champ.name] or 0) + 1
  if db.announceLocal then
    say(("champion: %s with %s avoidable damage%s. (/lava for the board)"):format(champ.name, Lava.Short(champ.amount),
      champ.deaths > 0 and ", and they died" or ""))
  end
  if ns.Refresh then ns.Refresh() end
  return champ
end

local pendingScan = false
function Lava.ScheduleScan()
  if pendingScan then return end
  pendingScan = true
  C_Timer.After(1.5, function() pendingScan = false; if not InCombatLockdown() then Lava.AfterCombat() end end)
end

-- /lava report: you typed it, so one line goes to party/raid (never during chat lockdown).
function Lava.Report()
  local last = db and db.last
  if not last or not last.rows[1] then say("no fight to report yet.") return end
  if not IsInGroup() then say("you're not in a group.") return end
  if C_ChatInfo.InChatMessagingLockdown and C_ChatInfo.InChatMessagingLockdown() then say("chat is locked right now; try after the fight.") return end
  local parts = {}
  for i = 1, math.min(3, #last.rows) do parts[i] = ("%d. %s %s"):format(i, last.rows[i].name, Lava.Short(last.rows[i].amount)) end
  C_ChatInfo.SendChatMessage("Floor is Lava (avoidable damage): " .. table.concat(parts, "  "), IsInRaid() and "RAID" or "PARTY")
end

function Lava.TopTally(n)
  local list = {}
  for name, count in pairs(db.tally) do list[#list + 1] = { name = name, count = count } end
  table.sort(list, function(a, b) if a.count ~= b.count then return a.count > b.count end return a.name < b.name end)
  local out = {}
  for i = 1, math.min(n or 5, #list) do out[i] = list[i] end
  return out
end

ns.Core.Setup({ cmd = "/lava",
  required = { "C_DamageMeter.IsDamageMeterAvailable", "C_DamageMeter.GetAvailableCombatSessions",
    "C_DamageMeter.GetCombatSessionFromID", "C_DamageMeter.GetCombatSessionFromType" },
  optional = { "Details", "SendChatMessage" },
  debugLines = function()
    local ok, available, why = pcall(C_DamageMeter.IsDamageMeterAvailable)
    return { "built-in damage meter available: " .. tostring(ok and available) .. (why and (" (" .. tostring(why) .. ")") or "") }
  end })

SLASH_FLOORISLAVA1 = "/lava"
SLASH_FLOORISLAVA2 = "/floorislava"
SlashCmdList.FLOORISLAVA = function(msg)
  msg = strtrim((msg or ""):lower())
  if msg == "debug" then ns.Core.PrintDebug()
  elseif msg == "report" then Lava.Report()
  elseif msg == "reset" then wipe(db.tally); db.last = nil; say("board and season tally cleared.")
  elseif msg == "solo" then db.groupOnly = not db.groupOnly; say(db.groupOnly and "only in groups." or "solo fights count too.")
  elseif msg == "quiet" then db.announceLocal = not db.announceLocal; say(db.announceLocal and "champion line on." or "champion line off.")
  elseif msg == "help" then
    say("/lava - the board   /lava report - post the top 3 to your group   /lava solo - count solo fights")
    say("/lava quiet - no champion line after fights   /lava reset - clear the season tally   /lava debug - check your setup")
  else if ns.Toggle then ns.Toggle() end end
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("ADDON_LOADED")
ev:RegisterEvent("PLAYER_REGEN_ENABLED")
ev:SetScript("OnEvent", function(_, event, name)
  if event == "ADDON_LOADED" and name == addonName then
    FloorIsLavaDB = FloorIsLavaDB or {}
    db = FloorIsLavaDB
    for k, v in pairs(defaults) do if db[k] == nil then db[k] = type(v) == "table" and {} or v end end
    Lava.db = db
  elseif event == "PLAYER_REGEN_ENABLED" then
    Lava.ScheduleScan()
  end
end)
