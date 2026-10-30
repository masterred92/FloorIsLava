# Changelog

## 1.0.1
- Checks for the built-in damage meter at login and says so if it is missing.
- `/lava debug` checks your setup: client version, every game API the addon needs, and which of Kenny's other addons it is working with.
- A loud chat warning if this client is missing an API the addon needs, instead of failing silently.
- English text now lives in `Locales/enUS.lua`, ready for translations.
- Shared code (KennyShared) is identical in every addon of the family and checked in CI, along with every Blizzard API call (against the Forever UI source) and every DBM/BigWigs/Questie API call (against their source).

## 1.0.0 (first release)
- First release. Details! toolbar plugin and board: avoidable damage taken and deaths per fight from C_DamageMeter, with class colours.
- Lava Lords season tally, a local champion line after group fights, and `/lava report` (top 3, only when you type it).
- Game version: WoW: Forever 1.60.1 (Interface 16001).
