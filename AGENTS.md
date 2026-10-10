# Local development and releases

- User preference: do not increment addon version numbers for local edits, fixes, game-directory syncs, or development builds. Change TOC versions, addon_version.txt, release tags and official version labels only when the user explicitly requests a formal release.
- Keep unreleased work in an Unreleased changelog section. Do not overwrite an existing release ZIP with development changes; use an ignored development output directory when checking packages.
- Back up replaced game files under workspace `_backups/`, sync authorized changes to the installed addon, and verify hashes. Never overwrite player SavedVariables.
