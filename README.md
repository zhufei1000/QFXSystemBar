# QFXSystemBar

QFXSystemBar is a World of Warcraft addon that provides a lightweight system bar, configurable micro menu buttons, info bar integration, locale packs, and MeetingStone-family bridge support.

## Contents

- `QFXSystemBar/` - core addon files and media assets
- `QFXSystemBar_Config/` - configuration UI module
- `QFXSystemBar_InfoBar/` - info bar integration module
- `QFXSystemBar_Locale_*/` - localization modules
- `QFXSystemBar_MeetingStone/` - MeetingStone and group-finder bridge module

## License

This project is released under the MIT License.

## Releases

Pushing a Git tag packages all addon modules, creates a GitHub Release, and
publishes the archive to CurseForge project `1533536`.

Before the first release, add a repository Actions secret named `CF_API_KEY`.
Then update the version in the TOC files and `QFXSystemBar/addon_version.txt`,
commit the release, and push an annotated tag:

```bash
git tag -a 1.8.06 -m "Release 1.8.06"
git push origin main 1.8.06
```
