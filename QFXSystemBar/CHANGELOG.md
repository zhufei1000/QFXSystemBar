# QFXSystemBar

## [1.8.12](https://github.com/zhufei1000/QFXSystemBar/tree/1.8.12) (2026-08-25)
[Full Changelog](https://github.com/zhufei1000/QFXSystemBar/compare/1.8.11...1.8.12) [Previous Releases](https://github.com/zhufei1000/QFXSystemBar/releases)

- Structure: merge the 10 `QFXSystemBar_Locale_*` sub-addons into a single load-on-demand `QFXSystemBar_Locale` module (14 addon folders -> 5); stale split installs keep working via a loader fallback
- Memory: free unused locale tables on registration - only the client locale (plus a forced language, if set) stays resident, cutting the locale footprint from ~560 KB to ~90 KB
- Language: switching to a language whose table was freed now asks for a UI reload (confirmation popup, blocked safely during combat)
- Localization: complete Spanish (esES/esMX) - translated all placeholder strings, added the 85 keys missing vs deDE/ruRU, player-native short labels (iLvl, M+, Espec., FPS/ping, Dura, Zona, Coords), official terms Vivienda / punto de ruta
- Localization: zhCN/zhTW complete the last missing key (volume tooltip); finished locales now carry a 464-key set

## [1.8.11](https://github.com/zhufei1000/QFXSystemBar/tree/1.8.11) (2026-08-25)
[Full Changelog](https://github.com/zhufei1000/QFXSystemBar/compare/1.8.10...1.8.11) [Previous Releases](https://github.com/zhufei1000/QFXSystemBar/releases)

- Localization: complete the French (frFR) locale - translated all placeholder strings and added the 85 keys missing vs deDE/ruRU (463-key set aligned)
- Localization: use player-native short labels on French info bars (iLvl, M+, Spé, FPS/ping, Dura, Zone, Coords, Phase, ACL, Son)
- Localization: adopt official French terms - Housing -> Logis, waypoint -> point de repère

## [1.8.10](https://github.com/zhufei1000/QFXSystemBar/tree/1.8.10) (2026-08-17)
[Full Changelog](https://github.com/zhufei1000/QFXSystemBar/compare/1.8.09...1.8.10) [Previous Releases](https://github.com/zhufei1000/QFXSystemBar/releases)

- Add compact English labels for 38 dropdown/row option keys to prevent UI overflow (Class Color modes, Hearthstone choices, native menu/bag bar rows, fade modes, line styles, counter rows)
- Localization notes document added: info bar short-label convention and English key length audit rules

## [1.8.09](https://github.com/zhufei1000/QFXSystemBar/tree/1.8.09) (2026-08-17)
[Full Changelog](https://github.com/zhufei1000/QFXSystemBar/compare/1.8.08...1.8.09) [Previous Releases](https://github.com/zhufei1000/QFXSystemBar/releases)

- Re-release of 1.8.08 with a bumped version after an accidental CurseForge upload
- Localization: complete the Russian (ruRU) locale - translated 217 missing strings and aligned the key set with deDE
- Localization: fix German (deDE) terms (Housing, Dalaran-Ruhestein, Allgemeine Einstellungen, Originalsymbole)
- Localization: use player-native short labels on info bars (iLvl, M+, Spec / Спека, Прочка, Скор) in deDE and ruRU

## [1.8.08](https://github.com/zhufei1000/QFXSystemBar/tree/1.8.08) (2026-08-15)
[Full Changelog](https://github.com/zhufei1000/QFXSystemBar/compare/1.8.07...1.8.08) [Previous Releases](https://github.com/zhufei1000/QFXSystemBar/releases)

- Performance: run locale application and SavedVariables migration once per database instance in the config UI
- Performance: only listen to GET_ITEM_INFO_RECEIVED / TOYS_UPDATED when a random hearthstone action is configured
- Performance: run InfoBar default migrations once per session
- Clean up dead code (unused button fields, no-op fade timer callback, unused options table, unreferenced bridge export)
- Share the equipped-durability scan between the micro menu and info bars
- Localization: complete the Russian (ruRU) locale - translated 217 missing strings and aligned the key set with deDE
- Localization: fix German (deDE) terms (Housing, Dalaran-Ruhestein, Allgemeine Einstellungen, Originalsymbole)
- Localization: use player-native short labels on info bars (iLvl, M+, Spec / Спека, Прочка, Скор) in deDE and ruRU

## [1.8.07](https://github.com/zhufei1000/QFXSystemBar/tree/1.8.07) (2026-08-13)
[Full Changelog](https://github.com/zhufei1000/QFXSystemBar/compare/1.8.06...1.8.07) [Previous Releases](https://github.com/zhufei1000/QFXSystemBar/releases)

- Coalesce InfoBar login refresh requests to reduce startup CPU spikes
- Avoid duplicate InfoBar initialization refreshes

## [1.8.06](https://github.com/zhufei1000/QFXSystemBar/tree/1.8.06) (2026-08-10)
[Full Changelog](https://github.com/zhufei1000/QFXSystemBar/commits/1.8.06) [Previous Releases](https://github.com/zhufei1000/QFXSystemBar/releases)

- Release 1.8.06 with WoW 12.1.0 support  
- Release 1.8.05: drag unlocked menu directly  
- Release 1.8.04: allow edge-aligned dragging  
- Release 1.8.03  
- Release 1.8.01: fix pinned-clock icon hover visibility  
    Merge PR #1 into main.  
- Bump version to 1.8.01  
- Fix pinned-clock icon hover visibility  
- Release version 1.8.00  
- Add top-center zone information positioning  
- Sync QFXSystemBar 1.7.99 source  
- Add contribution guidelines  
- Initial QFXSystemBar source release  
