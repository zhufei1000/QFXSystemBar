# QFXSystemBar

## 1.14.8 (2026-10-10)

- Add optional Great Vault and MRT micro menu buttons, combat-compatible panel toggles, and MRT click-to-close behavior. Preserve existing visibility and order settings.
- Ship matching white transparent MDT, MRT and Great Vault icons with normalized visible sizes, 256px DXT5 textures, vector mip levels and trilinear filtering.
- Add Mycomancer's Hearthspore to owned hearthstone choices and the random cosmetic hearthstone pool; add clock middle-click to reload outside combat.
- Add live Great Vault progress to the micro menu tooltip, using the game's activity counts, seasonal thresholds and unlocked reward slots.
- Add optional text-only Vault, MRT and MDT entries to each info bar's content/order settings. Reuse the menu shortcuts' toggles and combat/loading behavior; Vault text shares the progress tooltip.
- Unify the micro menu and info bar's Great Vault tooltips through one core renderer, matching the native panel, colors, spacing and click hint without requiring the info-bar module to load.
- Stop hover refresh immediately when an info item or menu button hides, and stop polling when a menu fades out or another frame owns the tooltip. Keep disabled info items from retaining tickers and prevent time/vault updates from hiding or replacing another tooltip.
- Remove unreachable legacy ticker cleanup, unused Vault tooltip metadata and obsolete MRT opening hints. Exclude developer instructions and audit notes from release archives.
- Validate 13 Lua regression suites, 22 runtime Lua files, all ten locale packs and the five-module release package. Actual client rendering and combat interaction still require in-game verification.

## 1.14.7 (2026-10-10)

- Make MRT left-click toggle its options window. MRT's compartment and slash entry points only open the panel; close an already shown `MRTOptionsFrame` directly, otherwise keep using the original opening/loading entry points.
- Preserve combat open/close for loaded MRT and out-of-combat lazy loading. Follow actual frame visibility when MRT is opened or closed through another launcher.

## 1.14.6 (2026-10-10)

- Reduce jagged outlines on MDT, MRT and Great Vault by selecting trilinear mip filtering in the live menu and configuration/drag previews. The 256px icons were being displayed with the default linear filter after 1.14.5, causing undersampling at small menu sizes.
- Keep the client-displayed DXT5 assets, fresh paths, artwork and normalized size from 1.14.5 unchanged. Offline sampling comparison covers 24-48px and subpixel positions; client appearance still requires confirmation after reload.

## 1.14.5 (2026-10-10)

- Fix garbled MDT, MRT and Great Vault textures reported in the client after 1.14.4. Replace RAW3/BGRA with the existing menu icons' BLP2/DXT5 format, retaining 256x256 SVG rendering and nine mip levels.
- Use fresh `*-256.blp` paths to bypass cached old texture metadata, remove forced trilinear filtering, and keep the approved artwork, white transparency and normalized size. Remove the superseded BLP resources.
- Offline decoding validates texture data; actual client rendering still requires an in-game check.

## 1.14.4 (2026-10-10)

- Rebuild MDT, MRT and Great Vault from the existing SVG artwork at 256x256 with lossless BLP2/BGRA alpha instead of DXT5 edge quantization. Render each of nine mip levels directly from its vector source, preserving the approved artwork and normalized size.
- Use trilinear filtering for these three icons in the live menu and configuration preview, retaining the default filter for other icons. Keep pure white RGB in transparent pixels to avoid dark edge fringes.

## 1.14.3 (2026-10-10)

- Normalize Great Vault, MDT and MRT artwork padding with shared square texture crops. Match the visible scale of existing menu icons, preserve logo proportions and apply the same crops in all four themes and the settings preview.

## 1.14.2 (2026-10-10)

- Replace the MRT letter-circle artwork with a clean white vector tracing of MRT's original circular ring and slanted monogram. Remove the original dark disk and keep transparent negative space; retain the existing white icon behavior across themes.

## 1.14.1 (2026-10-10)

- Allow Great Vault clicks during combat by toggling the native frame directly, matching installed EUI's shortcut. Load Blizzard_WeeklyRewards on the first click and avoid UIPanel dispatch that can close other panels.
- Allow an already loaded MRT to open during combat through its own entry point or slash handler, matching MDT. Keep missing-addon loading outside combat.
- Always use the bundled white MRT circular-outline icon in the live menu and settings preview, across all four themes and icon colors. Stop selecting MRT's native orange artwork.
- Verify combat open/close, first combat vault load, MRT public/slash combat calls, missing-core guards and white icon selection in regression tests. Client combat/taint behavior still requires in-game verification.

## 1.14.0 (2026-10-10)

- Add Mycomancer's Hearthspore (264367) to owned hearthstone choices and the cosmetic random pool. Use localized client item names, with translated fallbacks in all ten locale packs.
- Add optional, reorderable Great Vault and MRT buttons, disabled by default. Keep existing visibility/order settings; clicks are blocked in combat.
- Great Vault left-click toggles Blizzard's native weekly rewards panel, using its load-on-demand bootstrap. Ship an original white chest outline on a transparent background, shared by all icon themes.
- MRT left-click uses the addon's registered compartment entry point, with its /mrt handler as a fallback and optional loading on demand. Read MRT's own IconTexture metadata; use an original white MRT monogram if it is absent. Do not redistribute MRT artwork.
- Add clock middle-click to reload the interface outside combat, while keeping left-click calendar and right-click memory cleanup.
- Verify entry points against Retail Live 12.1.0.69933 and installed MRT 5330. Automated checks cover lazy loading, missing addons, combat, old settings, four icon themes, hearthspore ownership/usability/cooldown, and all ten locale packs; client interaction still needs an in-game check.

## 1.13.0 (2026-10-07)

- This release also includes the Macros button (left-click opens, right-click closes), independent extra-text font size, localized FPS/latency controls, and Discord/QQ/GitHub contact icons developed in the local 1.11.x and 1.12.x builds below.
- Fix mouseover fades so clock/blink and FPS tickers restart after the menu becomes visible and stop after it finishes fading out.
- Add an optional, reorderable MDT button. Left-click delegates opening/closing and lazy UI loading to Mythic Dungeon Tools' public ShowInterface API, with the registered /mdt handler as a compatibility fallback.
- Keep the button disabled by default, preserve saved visibility/order, and only attempt a missing core-addon load on a click outside combat. Installed MDT's own behavior controls calls once its API is available.
- Ship an MDT-inspired white shield/sword icon with a transparent background, shared across all menu themes and kept white under icon color settings. Include source attribution and the upstream license.
- Translate the button hint and missing-addon message in all ten locale packs. Verified integration against installed MDT 6.2.21 with its optional MythicDungeonTools_UI module; actual client interaction still requires in-game testing.

## 1.12.1 (2026-10-07)

- Add the skill's white GitHub contact icon beside Discord and QQ in settings. Clicking it opens the existing copy dialog with this addon's repository URL.
- Use the icon itself for hover highlighting across the contact row and translate the GitHub copy hint in all ten locale packs.

## 1.12.0 (2026-10-07)

- Add an independent 8–32 px extra-text font size in Micro Menu > Extra Text, shared by durability, friend/guild counts, bag slots, volume, FPS, and latency. Apply changes immediately without rebuilding secure buttons.
- Preserve the existing icon-derived extra-text size when migrating old settings. Clock and info-bar sizes remain independent.
- Translate the Game Menu FPS/latency toggle and tooltip, and the new size control, in all ten locale packs.

## 1.11.2 (2026-10-07)

- Fix Invalid frame handle errors when clicking Macros in combat: remove restricted references and the IsShown visibility query on the unprotected native MacroFrame.
- Use fixed SecureActionButtonTemplate actions: left-click opens via Blizzard's /macro command; right-click forwards to the native close button. These replace the previous left-click toggle in and out of combat.
- Update all ten locale packs with the separate open/close click hints. Keep saved button visibility and ordering unchanged.
- Regression checks forbid frame references, restricted wrappers, visibility queries, and addon click-handler replacements. Tests verify action configuration; the client's protected execution still requires in-game testing.

## 1.11.1 (2026-10-07)

- Allow the Macros button to open and close the native macro window during combat through SecureActionButtonTemplate and a secure click wrapper.
- Use Blizzard's /macro command to open and securely forward clicks to its native close button; preserve Blizzard's panel and macro-save behavior.
- Initialize Blizzard_MacroUI only when the optional button is enabled, before combat, and keep all frame-reference binding and wrapper setup out of combat.
- Verify against Retail Live 12.1.0.69933, UI source commit 09b9db7948abc9b9648dedaab51eb0cf3ee67b31. Automated tests emulate secure dispatch; actual client taint/combat behavior still requires an in-game check.

## 1.11.0 (2026-10-07)

- Add an optional Macros button to Button Order & Visibility, with drag ordering and matching GameIcons, Lucide, Tabler, and original-style fallback artwork.
- Left-click opens or closes the native macro window through Blizzard's load-on-demand ShowMacroFrame entry point. Combat clicks show the existing unavailable-in-combat message.
- Keep the new button disabled by default for both new and existing users; preserve current button visibility and order.
- Translate the new labels and messages for all ten locale packs and retain icon source attribution.

## [1.10.0](https://github.com/zhufei1000/QFXSystemBar/tree/1.10.0) (2026-10-05)
[Full Changelog](https://github.com/zhufei1000/QFXSystemBar/compare/1.9.1...1.10.0) [Previous Releases](https://github.com/zhufei1000/QFXSystemBar/releases)

- Performance: halve idle wakeups - info-bar coords ticker 1s to 2s and fps ticker 3s to 5s; drop the MeetingStone 10s poll (fully event-driven now); cache the 60-sample clock width scan per font
- Game Menu button: badge-style two-line FPS/latency readout (FPS on top, latency below) with the info bar's green/yellow/red thresholds and the same size as other extra texts; toggleable in Extra Text settings and on for fresh installs
- Game Menu hover: system tooltip (FPS, home/world latency, memory total) collapsed by default with Shift to expand the per-addon list, plus Left/Right click hints; hover-only refresh with zero idle cost
- Localization: add "Open Game Menu" and "Open AddOns" (translated for zhCN/zhTW, English fallback elsewhere)

## [1.9.1](https://github.com/zhufei1000/QFXSystemBar/tree/1.9.1) (2026-10-03)
[Full Changelog](https://github.com/zhufei1000/QFXSystemBar/compare/1.9.0...1.9.1) [Previous Releases](https://github.com/zhufei1000/QFXSystemBar/releases)

- Fix random hearthstone clicks by checking character usability and current cooldowns before the secure click, refreshing only the clicked random action, and updating cached ownership when toys or bags change. Keep a usable cooldown action when every eligible hearthstone is cooling down.

## [1.9.0](https://github.com/zhufei1000/QFXSystemBar/tree/1.9.0) (2026-09-23)
[Full Changelog](https://github.com/zhufei1000/QFXSystemBar/compare/1.8.22...1.9.0) [Previous Releases](https://github.com/zhufei1000/QFXSystemBar/releases)

- EllesmereUI: add a "Match EllesmereUI Skin" info-bar option (on by default) that follows the live EUI theme - panel-colored bar bodies, accent-colored rails, the EUI UI font and a themed volume panel; it updates live when accent/theme change and falls back to the QFX look when EUI is missing or its third-party skinning for this addon is off
- Tooltips: replace the "Left Click / Right Click / Middle Click" wording in micro-menu tooltips with the same inline mouse-button icons the info bars already use; works in all ten locales without touching any dictionary
- Info bars: size the text box from the font size (1.9x plus outline room) so tall UI fonts and CJK fallback glyphs are no longer clipped by SetClipsChildren
- MeetingStone: add a combat fix to the MeetingStone bridge that strips the protected UIPanel layout attributes from MeetingStone's main panel, so it can be opened in combat again without ADDON_ACTION_BLOCKED; it also silences the 12.1 LibShowUIPanel nil-delegate crash
- Performance: stop the clock and colon-blink tickers while the micro menu is faded out and restart them from every reveal path instead of polling a hidden bar forever
- Fixes: stop deleting keys while iterating the cached settings pages, fix the recursive IsAddOnLoaded fallbacks, keep the four shared info-bar defaults from being overwritten by the defaults table literal, add the missing clock-number Y-offset dependency, only watch for EllesmereUI before login, and skip disabled items when EUI looks change
- Cleanup: remove dead code (unused renderers, orphan option-map entries, unreferenced APIs, obsolete migration markers, unreachable branches) and unused locale keys; add the missing "Close" translation
- Localization: keep all ten locales aligned at 494 keys; every addon Lua file passes syntax checks and the unit tests pass

## [1.8.22](https://github.com/zhufei1000/QFXSystemBar/tree/1.8.22) (2026-09-17)
[Full Changelog](https://github.com/zhufei1000/QFXSystemBar/compare/1.8.21...1.8.22) [Previous Releases](https://github.com/zhufei1000/QFXSystemBar/releases)

- Mounts: hide collected mounts restricted to the opposing faction from the info-bar click-action selectors; keep neutral mounts, random favorite and no action available without background polling.
- Settings: sync the embedded QFXWidgets factory to VERSION 51, increase row/control text to 14px and section titles to 15px, and use the complete mipmapped v3 brand watermark with its source colours.
- Performance: cache the available random hearthstones at login and draw from shuffled decks instead of rescanning toys for every selection; avoid high-frequency item-info refreshes and throttle on-demand addon memory/CPU scans.
- Cleanup: remove unused info-bar tooltip implementations, obsolete brand image variants and an outdated bundled README; exclude development tools from release packages.
- Tests: cover both faction mount lists, random hearthstone deck behaviour, factory refresh ownership and deferred startup loads; all addon Lua files pass syntax checks.

## [1.8.21](https://github.com/zhufei1000/QFXSystemBar/tree/1.8.21) (2026-09-16)
[Full Changelog](https://github.com/zhufei1000/QFXSystemBar/compare/1.8.18...1.8.21) [Previous Releases](https://github.com/zhufei1000/QFXSystemBar/releases)

- Info bars: add a mount item with independently configurable left, middle and right-click actions; collected mounts are searchable and Blizzard's native random-favorite mount action is included automatically
- Info bars: display primary professions, secondary professions and configured mount actions as cropped 18px native icons with a fixed 3px gap; mount tooltips identify all three mouse-button assignments
- Talents: left-clicking the specialization item now opens the saved talent-loadout menu, while right-click continues to select the loot specialization
- Settings: add localized mount controls and refresh the embedded QFXWidgets presentation with branded chrome, sharper rounded controls, improved sliders, tabs and section layout
- Assets: move the Game Icons, Lucide and Tabler micro-menu sets to mipmapped BLP artwork and add the new settings/brand textures used by the refreshed interface
- Compatibility: support the current 12.0.5 talent-loadout API with legacy fallbacks; keep all ten translated locales aligned with the expanded 492-key base set

## [1.8.18](https://github.com/zhufei1000/QFXSystemBar/tree/1.8.18) (2026-09-15)
[Full Changelog](https://github.com/zhufei1000/QFXSystemBar/compare/1.8.17...1.8.18) [Previous Releases](https://github.com/zhufei1000/QFXSystemBar/releases)

- Settings: expand the embedded QFXWidgets factory with refreshable notes/status rows, delayed tab-page refresh ownership, standalone control disabled states and consistent per-row refresh hooks
- Dropdowns: keep only one menu open, close menus with their host, match scaled anchors, add deterministic outside-click handling to searchable lists, and show item tooltips reliably
- Fixes: include section headers in header-plus-note layout height, reverse scrollbar thumb drag math to match visual movement, and keep drag-reorder row frames synchronized with their data order
- Fixes: commit text and slider edits once on focus loss/release while preserving Escape cancellation; improve left-click key capture and boolean-or-function disabled flags
- Fixes: preserve color-picker alpha/cancel values, retry LibSharedMedia discovery when it loads late, report failed sound playback correctly, and expose accurate dynamic list counts

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
