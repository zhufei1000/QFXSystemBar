# QFXSystemBar

QFXSystemBar is a World of Warcraft addon that provides a lightweight system bar, configurable micro menu buttons, info bar integration, locale packs, and MeetingStone-family bridge support.

## Contents

- `QFXSystemBar/` - core addon files and media assets
- `QFXSystemBar_Config/` - configuration UI module
- `QFXSystemBar_InfoBar/` - info bar integration module
- `QFXSystemBar_Locale/` - load-on-demand localization module (all languages, one per file)
- `QFXSystemBar_MeetingStone/` - MeetingStone and group-finder bridge module

## Utility shortcuts

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
git tag -a 1.14.8 -m "Release 1.14.8"
git push origin main 1.14.8
```

Release archives use the name `QFXSystemBar_<version>.zip`. To keep a local
package before publishing, run `python tests/build_release_zip.py`.
