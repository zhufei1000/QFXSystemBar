# QFXSystemBar

QFXSystemBar is a World of Warcraft addon that provides a lightweight system bar, configurable micro menu buttons, info bar integration, locale packs, and MeetingStone-family bridge support.

## Contents

- `QFXSystemBar/` - core addon files and media assets
- `QFXSystemBar_Config/` - configuration UI module
- `QFXSystemBar_InfoBar/` - info bar integration module
- `QFXSystemBar_Locale/` - load-on-demand localization module (all languages, one per file)
- `QFXSystemBar_MeetingStone/` - MeetingStone and group-finder bridge module

## License

This project is released under the MIT License.
Third-party artwork retains its own license; see the attribution and license
files alongside the media. The adapted MDT logo and its editable SVG source
are supplied under GPL v2 in `QFXSystemBar/Media/MicroMenu/`.

## Releases

Pushing a Git tag packages all addon modules, creates a GitHub Release, and
publishes the archive to CurseForge project `1533536`.

Before the first release, add a repository Actions secret named `CF_API_KEY`.
Then update the version in all five modules' TOC files and `addon_version.txt`,
commit the release, and push an annotated tag:

```bash
git tag -a 1.13.0 -m "Release 1.13.0"
git push origin main 1.13.0
```

Release archives use the name `QFXSystemBar_<version>.zip`. To keep a local
package before publishing, run `python tests/build_release_zip.py`.
