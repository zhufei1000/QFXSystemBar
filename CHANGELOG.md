# QFXSystemBar

## [1.8.17](https://github.com/zhufei1000/QFXSystemBar/tree/1.8.17) (2026-09-15)
[Full Changelog](https://github.com/zhufei1000/QFXSystemBar/compare/1.8.16...1.8.17) [Previous Releases](https://github.com/zhufei1000/QFXSystemBar/releases)

- Localization: complete the Italian (itIT) and Korean (koKR) locales - translated all 83 missing keys and ~110 English placeholder strings each, including the appearance, clock, info-bar and button-badge settings (480-key set)
- Localization: complete German, Spanish (esES/esMX), French, Portuguese and Russian - added the 16 keys missing since 1.8.14 (profession icons, nudge position, clock number offset, confirm, unknown) plus the remaining placeholders (Quests, Score, Mythic+, Credits, Game Icons, Vol); every locale now passes the deDE parity check with zero missing or untranslated entries
- Fixes: settings pages no longer cancel each other's refresh callbacks when switching pages, so position coordinates, info-bar counters and check grids stay live on cached pages
- Fixes: tooltips no longer replace existing hover feedback (button, dropdown and reset-row highlights work again), and the slider's per-frame OnUpdate only runs while dragging (menus and scrollbars too)
- Fixes: sliders commit once on release instead of every drag tick, notes measure their wrapped height before layout, factory menus keep the host refresh hook, and the check-grid limit check is a single pass
- Fixes: a combat-blocked micro-menu re-position is applied on PLAYER_REGEN_ENABLED instead of leaving the bar visually stale, and the position status text uses the already-translated strings
- Tests: add a QFXWidgets refresh-registry regression test (owner scoping with a foreign global owner) and extend the locale parity whitelist

## [1.8.16](https://github.com/zhufei1000/QFXSystemBar/tree/1.8.16) (2026-09-15)
[Full Changelog](https://github.com/zhufei1000/QFXSystemBar/compare/1.8.15...1.8.16) [Previous Releases](https://github.com/zhufei1000/QFXSystemBar/releases)

- Settings: rebuild the popup settings window on the QFXWidgets factory, embedded in this addon so the package stays self-contained; every control is factory-drawn now (blue/navy skin, compact rows, switches with a short slide animation, segmented pills, colour swatches without outlines, checkbox grids with a max-5 limit, factory scroll page with a self-drawn bar, factory tab navigation)
- Settings: replace the native close button, backdrop, scroll frame and page tabs with factory chrome; the window no longer closes together with the Blizzard options panel on the same ESC press (opt in with `QFXSystemBarNS.closeOnEscape = true`); remove the legacy UI builders (~970 lines)
- Settings: the button list and info-bar content pages use factory check grids (the per-bar 5-item limit is enforced and shown live), position pages collapse into one row (description left, four half-width nudge buttons right) with a live coordinate row and a factory reset row
- Fixes: dragging a slider no longer fights the page refresh (the value is committed once on release, the fill is whole-pixel), dropdown menus close through a click catcher so items always select, borders are sized in physical pixels so they are no longer shaved at fractional UI scales, long labels ellipsize after layout, and long menus scroll
- Localization: add the `Nudge Position` and `Current Position` keys (zhCN/zhTW); other locales fall back to English

## [1.8.15](https://github.com/zhufei1000/QFXSystemBar/tree/1.8.15) (2026-09-10)
[Full Changelog](https://github.com/zhufei1000/QFXSystemBar/compare/1.8.14...1.8.15) [Previous Releases](https://github.com/zhufei1000/QFXSystemBar/releases)

- Localization: complete the Brazilian Portuguese (ptBR) locale - translated all placeholder strings, added the 85 keys missing vs deDE/ruRU, player-native short labels (iLvl, M+, Espec., FPS/ping, Dura, Zona, Coords, Fase, ACL, Som), official terms Moradia / ponto de rota (464-key set aligned)
- Fixes: guard the main-menu right-click action against combat so it no longer triggers a crash in MeetingStone's bundled LibShowUIPanel-1.0

## [1.8.14](https://github.com/zhufei1000/QFXSystemBar/tree/1.8.14) (2026-09-03)
[Full Changelog](https://github.com/zhufei1000/QFXSystemBar/compare/1.8.13...1.8.14) [Previous Releases](https://github.com/zhufei1000/QFXSystemBar/releases)

- Settings: add wide, EUI-style drag previews for top micro-menu and info-bar ordering; remove the old item-order arrows and place each info bar's content controls directly below its enable switch
- Professions: add auto-detected primary and secondary profession icons using native game art, with left/right/middle-click shortcuts and compact spacing
- Group finder: show `集合石` for MeetingStone and compact addon names for alternatives (`PGB` for PremadeGroupBoard); left-click opens the detected addon's UI
- Tooltips: automatically open away from the nearest screen edge for both info bars and the top micro menu without adding a background ticker
- Fixes: keep equal-width info-bar cells stable, localize durability slot names correctly, include reagent-bag space, throttle guild roster requests, and improve the outlined blinking clock colon
- Assets: refresh themed icons, include their licenses, and remove unused preview/legacy icon files

## [1.8.13](https://github.com/zhufei1000/QFXSystemBar/tree/1.8.13) (2026-08-31)
[Full Changelog](https://github.com/zhufei1000/QFXSystemBar/compare/1.8.12...1.8.13) [Previous Releases](https://github.com/zhufei1000/QFXSystemBar/releases)

- Publishing: automatically attach this English changelog to each CurseForge file (markdown release notes)
- Packaging: stop shipping dev-only files (localization notes, test scripts) inside the addon package; refresh the packager folder map for the merged locale module

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
