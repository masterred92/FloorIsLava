-- The scoreboard window and the Details! toolbar button.
local addonName, ns = ...
local Lava = ns.Lava

local DETAILS_MIN = 172 -- Details.realversion whose InstallPlugin / ToolBar API this uses
local ICON = "Interface\\AddOns\\FloorIsLava\\media\\icon"
local frame, rows

local function build()
  frame = CreateFrame("Frame", "FloorIsLavaBoard", UIParent, "BackdropTemplate")
  frame:SetSize(300, 290)
  frame:SetPoint("CENTER")
  frame:SetFrameStrata("DIALOG")
  frame:SetMovable(true)
  frame:EnableMouse(true)
  frame:RegisterForDrag("LeftButton")
  frame:SetScript("OnDragStart", frame.StartMoving)
  frame:SetScript("OnDragStop", frame.StopMovingOrSizing)
  frame:SetBackdrop({ bgFile = "Interface\\DialogFrame\\UI-DialogBox-Background", edgeFile = "Interface\\Tooltips\\UI-Tooltip-Border",
    tile = true, tileSize = 16, edgeSize = 16, insets = { left = 4, right = 4, top = 4, bottom = 4 } })
  local title = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalLarge")
  title:SetPoint("TOP", 0, -12)
  title:SetText("Floor is Lava")
  frame.sub = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlightSmall")
  frame.sub:SetPoint("TOP", title, "BOTTOM", 0, -4)
  local close = CreateFrame("Button", nil, frame, "UIPanelCloseButton")
  close:SetPoint("TOPRIGHT", -2, -2)
  rows = {}
  for i = 1, 10 do
    local fs = frame:CreateFontString(nil, "ARTWORK", "GameFontHighlight")
    fs:SetPoint("TOPLEFT", 16, -52 - (i - 1) * 16)
    fs:SetJustifyH("LEFT")
    rows[i] = fs
  end
  frame.tally = frame:CreateFontString(nil, "ARTWORK", "GameFontNormalSmall")
  frame.tally:SetPoint("BOTTOMLEFT", 16, 14)
  frame.tally:SetJustifyH("LEFT")
  frame:Hide()
end

local function classColor(class)
  local c = class and RAID_CLASS_COLORS and RAID_CLASS_COLORS[class]
  return c and c.colorStr and ("|c" .. c.colorStr) or "|cffffffff"
end

function ns.Refresh()
  if not frame or not frame:IsShown() then return end
  local last = Lava.db.last
  frame.sub:SetText(last and ("last fight, " .. date("%H:%M", last.at)) or "no fight yet")
  for i = 1, 10 do
    local r = last and last.rows[i]
    rows[i]:SetText(r and ("%s%d. %s|r  %s%s"):format(i == 1 and "|cffff6a00" or "", i, classColor(r.class) .. r.name .. "|r",
      Lava.Short(r.amount), r.deaths > 0 and "  (died)" or "") or "")
  end
  local t = {}
  for _, e in ipairs(Lava.TopTally(3)) do t[#t + 1] = ("%s x%d"):format(e.name, e.count) end
  frame.tally:SetText(#t > 0 and ("Lava Lords: " .. table.concat(t, ", ")) or "")
end

function ns.Toggle()
  if not frame then build() end
  if frame:IsShown() then frame:Hide() else frame:Show(); ns.Refresh() end
end

-- Details! plugin (TOOLBAR type, like Details' own Raid Check plugin). Everything here is guarded.
function ns.InstallDetails()
  if ns.plugin then return true end
  local D = Details
  if type(D) ~= "table" or type(D.NewPluginObject) ~= "function" or type(D.InstallPlugin) ~= "function" then return false end
  if (tonumber(D.realversion) or 0) < DETAILS_MIN then Lava.say("Details! is older than this version supports; update Details!.") return false end
  local ok, plugin = pcall(D.NewPluginObject, D, "FloorIsLavaDetailsPlugin", DETAILSPLUGIN_ALWAYSENABLED, "TOOLBAR")
  if not ok or type(plugin) ~= "table" then return false end
  function plugin.OnDetailsEvent(_, event)
    if event == "COMBAT_PLAYER_LEAVE" then Lava.ScheduleScan() end
  end
  local okI, install = pcall(D.InstallPlugin, D, "TOOLBAR", "Floor is Lava", ICON, plugin, "DETAILS_PLUGIN_FLOORISLAVA", DETAILS_MIN, "Kenny",
    C_AddOns.GetAddOnMetadata(addonName, "Version") or "1")
  if not okI or (type(install) == "table" and install.error) then return false end
  if D.ToolBar and D.ToolBar.NewPluginToolbarButton then
    local okB, button = pcall(D.ToolBar.NewPluginToolbarButton, D.ToolBar, ns.Toggle, ICON, "Floor is Lava",
      "Who took the most avoidable damage last fight", 16, 16, "FLOORISLAVA_PLUGIN_BUTTON")
    if okB and button then plugin.ToolbarButton = button; pcall(plugin.ShowToolbarIcon, plugin, button, "star") end
  end
  pcall(D.RegisterEvent, D, plugin, "COMBAT_PLAYER_LEAVE")
  ns.plugin = plugin
  return true
end

local ev = CreateFrame("Frame")
ev:RegisterEvent("PLAYER_LOGIN")
ev:SetScript("OnEvent", function()
  C_Timer.After(1, ns.InstallDetails) -- after Details' own plugins, as Details' Raid Check does
end)
