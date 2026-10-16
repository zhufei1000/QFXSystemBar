# 12.1.5 动作条冷却污染排查

## 已确认与尚未确认

反馈仅提供 `ActionButton.lua:847` / `ActionButton_ApplyCooldown:866` 的末尾堆栈，未提供完整调用链、首次触发操作或 taint.log；据此不能确认污染源是 QFXSystemBar，也不能确认只在战斗中发生。

已核对 Gethe/wow-ui-source 的 `12.1.5` 标签，version.txt 为 **12.1.5.70391**，与本地整合项目保存的 API 快照版本一致：

- [FrameAPICooldownDocumentation.lua](https://github.com/Gethe/wow-ui-source/blob/12.1.5/Interface/AddOns/Blizzard_APIDocumentationGenerated/FrameAPICooldownDocumentation.lua)：`SetCooldown` 是受保护方法，`SecretArguments = "AllowedWhenUntainted"`。这些参数可以在受限制情境中成为秘密值，并非始终是秘密值。
- [ActionButton.lua](https://github.com/Gethe/wow-ui-source/blob/12.1.5/Interface/AddOns/Blizzard_ActionBar/Shared/ActionButton.lua)：第 847 行是暴雪消费冷却值的位置，并不指明污染最初产生在哪里。
- [MainMenuBarMicroButtons.lua](https://github.com/Gethe/wow-ui-source/blob/12.1.5/Interface/AddOns/Blizzard_MicroMenu/Mainline/MainMenuBarMicroButtons.lua)：原生 OnShow 负责布局或事件注册，覆盖再清空它会丢失原生行为。

QFXSystemBar 没有直接调用 `SetCooldown`、修改动作条按钮、替换动作条更新函数或挂钩 Cooldown 元表。原生按钮点击使用 SecureActionButtonTemplate 的 click 转发，保留该路径。

## 本次修补

- 原生微型菜单、背包栏及其按钮不再调用 `SetScript("OnShow", ...)` 替换／清空暴雪脚本。一次性 HookScript 只排队隐藏操作，不在原生 OnShow 内同步 Hide。
- 隐藏状态存在插件私有弱键表中，不给原生框架添加状态字段；恢复原先可见或在隐藏期间由原生系统显示过的按钮，不强行显示原先隐藏的背包格等按钮。
- 队列实际执行时再次检查 InCombatLockdown；原生 OnShow 的延迟隐藏同样检查战斗状态。战斗中等待 PLAYER_REGEN_ENABLED 再应用。
- 这些修补解决已确认的脚本破坏与战斗时序问题，**尚未证明能消除反馈中的动作条冷却报错**。没有吞掉 SetCooldown 错误或更改其参数，也没有尝试清除污染。

## 验证

- 15 个 Lua 回归套件通过，其中新增 NativeVisibility_test.lua 覆盖原生脚本保留、隐藏恢复、原生重新显示、延迟隐藏取消，以及入队后进入战斗和战斗中 OnShow 的时序。
- 25 个运行 Lua 文件通过 luac -p。
- 自动化测试不能模拟 WoW 的污染传播／秘密值执行边界；这些结论必须由客户端复测补充。
- 所有五个子包保留 **1.14.9**；不修改 TOC、更新器版本标记或 SavedVariables，不创建／覆盖正式发布 ZIP。

## 客户端复测与取证

1. 复制修补后先 `/reload`，让框架从干净会话重新创建。当前会话已被旧代码覆盖的脚本不能靠文件同步恢复。
2. 切换原生菜单／背包栏的显示、隐藏与鼠标悬停模式；确认原生按钮、背包格、商店和冒险指南正常。点击自定义天赋／法术书按钮，然后观察技能冷却。
3. 登录后进入普通战斗以及大秘境／团本战斗，连续触发公共冷却、技能冷却、充能与脱战；观察是否刷出同一错误。原生栏在战斗中被暴雪重新显示时，隐藏请求等待脱战。
4. 若仍复现，输入 `/console taintLog 2` 后 `/reload`，从新会话重现一次并正常退出游戏；提供 `D:/World of Warcraft/_retail_/Logs/taint.log` 的相关段落及完整错误堆栈。重点是首次出现 QFXSystemBar 或其他插件污染相关变量／执行路径的上下文，不能只保留最后的 SetCooldown 报错。
5. 完成取证后 `/console taintLog 0`，并 `/reload`。同时提供仅启用 QFXSystemBar 必需子包时是否复现的结果，以区分独立问题和插件交互。

## 同步与回滚

修改前，五个子包的源码、整合副本、客户端均为 1.14.9，已有 Lua／TOC 哈希一致。只同步本次修改的 `QFXSystemBar/QFXSystemBar.lua`：

- 源码：`D:/我发布的插件/微型菜单插件/QFXSystemBar/QFXSystemBar/QFXSystemBar.lua`
- 整合：`D:/我发布的插件/群飞轩UI/integrations/QFXSystemBar/QFXSystemBar.lua`
- 客户端：`D:/World of Warcraft/_retail_/Interface/AddOns/QFXSystemBar/QFXSystemBar.lua`

覆盖前备份：源码工作区 `_backups/taint_20261016_183920/` 及整合项目 `archive/QFXSystemBar_taint_20261016_183920/`，分别保留 source、integration、client 文件。回滚时使用对应来源的备份还原三处运行文件，再校验 SHA-256 并重载。

新增 `tests/NativeVisibility_test.lua` 和本排查文档，更新 CHANGELOG.md 的 Unreleased；开发文件不复制到客户端或运行副本。
