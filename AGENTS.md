# Local development and releases

- User preference: do not increment addon version numbers for local edits, fixes, game-directory syncs, or development builds. Change TOC versions, addon_version.txt, release tags and official version labels only when the user explicitly requests a formal release.
- Keep unreleased work in an Unreleased changelog section. Do not overwrite an existing release ZIP with development changes; use an ignored development output directory when checking packages.
- Back up replaced game files under workspace `_backups/`, sync authorized changes to the installed addon, and verify hashes. Never overwrite player SavedVariables.

## 独立维护范围

- 本插件按独立项目维护，不随群飞轩整合包分发，不要求维护 integrations 副本或整包全量回同步。管理中心现有专属适配与公开设置桥接继续保留并维护；不随包分发不代表取消专属适配。
- 本地修改与游戏同步保留版本号，仅在用户明确要求正式发布时递增。
