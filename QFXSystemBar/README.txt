QFXSystemBar 1.8.04

Localized lightweight system bar focused on the custom micro menu.

Features:
- Popup configuration window via /qfxbar
- Reorderable micro menu buttons
- MeetingStone button support
- Four icon styles: Original, Game Icons, Lucide, Tabler
- Random hearthstone option and direct wormhole click actions
- Separate left/middle/right hearthstone click settings
- Button counters for durability, friends, guild members, and free bag slots
- Info-bar gold tooltip with current-session earned, spent, and net values
- Info-bar time tooltip with on-demand raid lockout progress and reset times
- Unlock and drag positioning with 1-pixel nudge controls
- Native-looking compact popup settings UI

This build includes the custom micro menu and optional info bars. It supports client-language localization and manual language override.

Load-on-demand modules:
- QFXSystemBar_Config: popup configuration UI, loaded when /qfxbar or /qsb opens settings.
- QFXSystemBar_InfoBar: optional info bars, loaded when info bars are enabled or when settings need info-bar controls.
- QFXSystemBar_Locale_*: non-English locale packs, loaded only for the selected/client language.
- QFXSystemBar_MeetingStone: MeetingStone floating-window and broker compatibility bridge, loaded only when MeetingStone replacement behavior is needed.

English text is the source fallback and does not require an enUS locale table.

Supported Interface:
120005, 120007
