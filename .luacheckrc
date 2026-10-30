std = "lua51"
max_line_length = false
exclude_files = { "tests/**", "tools/**", ".release/**", ".lua/**", ".luarocks/**", "wow-ui/**", "index/**", "hosts/**" }
-- Our own globals.
globals = { "FloorIsLava", "FloorIsLavaDB", "SLASH_FLOORISLAVA1", "SLASH_FLOORISLAVA2", "SlashCmdList" }
-- WoW API (checked against Blizzard's UI source by tools/verify_api.py) and host-addon globals (tools/host_api.py).
read_globals = { "C_DamageMeter", "C_Timer", "C_ChatInfo", "C_AddOns", "Enum", "CreateFrame", "UIParent", "InCombatLockdown", "IsInGroup", "IsInRaid", "RAID_CLASS_COLORS", "issecretvalue", "strtrim", "wipe", "time", "date", "Details", "DETAILSPLUGIN_ALWAYSENABLED",
  -- used by the shared KennyShared library (Libs/KennyShared)
  "C_AuctionHouse", "C_Container", "C_Item", "C_RestrictedActions", "GameTooltip", "GetBuildInfo", "GetLocale", "GetMoney", "GetMoneyString", "GetRealZoneText", "GetRealmName", "GetSubZoneText", "GetTime", "ItemRefTooltip", "LibStub", "NUM_BAG_SLOTS", "NUM_TOTAL_EQUIPPED_BAG_SLOTS", "TooltipDataProcessor", "UnitAffectingCombat", "UnitFactionGroup" }
