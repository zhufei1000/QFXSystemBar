# QFXSystemBar

QFXSystemBar is a World of Warcraft addon that provides a lightweight system bar, configurable micro menu buttons, info bar integration, locale packs, and MeetingStone-family bridge support.

## Contents

- `QFXSystemBar/` - core addon files and media assets
- `QFXSystemBar_Config/` - configuration UI module
- `QFXSystemBar_InfoBar/` - info bar integration module
- `QFXSystemBar_Locale/` - load-on-demand localization module (all languages, one per file)
- `QFXSystemBar_MeetingStone/` - MeetingStone and group-finder bridge module

## Utility shortcuts

The optional Macros button uses left-click to open or close Blizzard's macro
window in and out of combat. Right-click has no action. It also works when
QFXAddonManager enlarges the native macro window; that extension is optional.

In `/qfxbar` > Micro Menu > Button Order & Visibility, enable Great Vault or MRT
and drag them into place. Both are disabled by default. Great Vault left-click
opens/closes Blizzard's rewards panel; MRT left-click opens/closes Method Raid Tools
when installed. Great Vault supports combat clicks; loaded MRT keeps its own
combat behavior, matching the MDT shortcut. MRT uses a white transparent icon.

Great Vault hover shows each activity category's completion count and unlocked
reward slots, using the game's current thresholds. In `/qfxbar` > Info Bar,
enable Vault, MRT or MDT in a bar's content settings and adjust their order.
These optional shortcuts display text only; Vault hover shares the progress
readout, and left-click toggles the corresponding panel.

Clock: left-click opens the calendar, right-click cleans memory, middle-click
reloads the interface outside combat. Owned Mycomancer's Hearthspore is available
as a hearthstone click action and in the random cosmetic hearthstone pool.

## Crests and account gold

In `/qfxbar` > Info Bar, enable the five Midnight upgrade crests (Adventurer
through Myth) in a bar's content settings. Each crest shows the currency icon
with its live amount, a tooltip with the weekly progress, and counts as 0.4 of
the bar's five item slots so a full row of crests shares two ordinary cells.

The gold tooltip lists every recorded character with gold totals, the warband
bank reading and the session profit/loss. Characters are recorded when they
log in or their money changes. Ctrl+Left Click on the gold item clears the
records after a confirming second press.

## Group finder integration

The MeetingStone menu button and info-bar item also support GroupFinder,
PremadeGroupBoard and Lychee LFG, in that priority after MeetingStone. Lychee
uses its native window toggle, including combat clicks, and its floating-entry
API supplies live application status and the hover list. The hosted entry keeps
the configured MeetingStone icon and restores standalone mode when released.

## License

This project is released under the MIT License.
Third-party artwork retains its own license; see the attribution and license
files alongside the media. The adapted MDT logo and its editable SVG source
are supplied under GPL v2 in `QFXSystemBar/Media/MicroMenu/`.

## Releases

Local development and game-directory syncs keep the current addon version.
Increment version numbers only when performing an explicitly requested formal
release. Keep development packages separate from existing release archives.

Pushing a Git tag packages all addon modules, creates a GitHub Release, and
publishes the archive to CurseForge project `1533536`.

Before the first release, add a repository Actions secret named `CF_API_KEY`.
Then update the version in all five modules' TOC files and `addon_version.txt`,
commit the release, and push an annotated tag:

```bash
git tag -a 1.15.0 -m "Release 1.15.0"
git push origin main 1.15.0
```

Release archives use the name `QFXSystemBar_<version>.zip`. To check a local
development package, run `python tests/build_release_zip.py`; the default output
is `.release/QFXSystemBar_<version>_dev.zip`. Existing files are preserved unless
`--overwrite` is explicitly supplied. Use `--output <path>` to select another
destination. This does not change addon versions or publish a release.

Both packaging paths omit PNG/SVG artwork sources and redundant theme TGA files
whose BLP versions are used at runtime. Keep these source files in the repository
for the icon-generation tools.
