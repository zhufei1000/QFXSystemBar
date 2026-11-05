# 魔兽世界：无限兼容适配

正式发布版本为 1.16.0，五个模块只声明正式服 12.1.5（120105）和无限版 1.60.1（16001）。此前开发适配保留 1.15.0，原有开发包和历史发布包保留。

## 客户端依据

- 核对 UI 源码：Gethe/wow-ui-source 的 `forever` 分支，`version.txt` 为 **1.60.1.70790**。
- 客户端资源记录接口号 **16001**，UI Family 为 `Mainline`，Game 为 `Camelot`，项目常量为 `WOW_PROJECT_CAMELOT`。
- [客户端资源记录](https://github.com/Ketho/BlizzardInterfaceResources/tree/forever)
- [无限版微型菜单](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_MicroMenu/Camelot/MicroMenuContainerOverrides.lua)
- [无限版原生按钮适配](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_MicroMenu/Camelot/MainMenuBarMicroButtonsOverrides.lua)
- [专精 API](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_APIDocumentationGenerated/SpecializationInfoDocumentation.lua)
- [旧专精接口加载范围](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_DeprecatedSpecialization/Blizzard_DeprecatedSpecialization.toc)
- [无限版收藏功能开关](https://github.com/Gethe/wow-ui-source/blob/forever/Interface/AddOns/Blizzard_Collections/Camelot/Blizzard_CollectionsConstants.lua)

## 实现范围

- 五个 TOC 增加 16001；主 TOC 在 Defaults.lua 前加载新增 Compat.lua。
- 保留 `PlayerSpells` 的配置 ID，无限版将其转发到 `TalentMicroButton`。新增 `SpellBook` 和 `Legacy` 配置 ID，对应独立原生按钮，继续使用安全点击转发。
- 旧配置只补充缺少的字段和排序项；法术书默认继承原天赋按钮的开关，已有的独立开关保留。其他按钮的相对顺序、坐标、外观和点击配置不变。
- 原生家宅、组队、专业、收藏等入口按无限版菜单的 GameRule 判断，冒险指南使用 `GameRulesUtil.EJIsDisabled`。窗口行为继续交给客户端原生按钮。
- 当前无限版不展示正式服宝库、MDT、大秘境评分和 Midnight 纹章；保留相应保存值，隐藏内容不占信息条的五格预算。MDT 公开入口也不加载或打开插件。金币提示不读取战团银行。上述客户端差异集中在 Compat.lua，后续玩法变化时在此调整。
- 无限版新配置的原生微型菜单和背包栏默认始终显示（模式 0）；已有保存的显隐模式不自动覆盖。正式服仍沿用原默认值。
- 专精读取优先调用 `C_SpecializationInfo`，保留旧客户端函数回退。天赋方案菜单的原生窗口回退优先使用当前分支的天赋按钮。
- 无限版随机坐骑在点击时筛选已收集、可用、未隐藏且符合阵营的坐骑；没有候选时不召唤。正式服仍使用随机偏好坐骑。现有 `random` 保存值保持不变。
- 保留炉石的拥有/可用性筛选，以及集合石、荔枝、MRT 的可选插件入口。第三方插件本身是否支持无限版仍由对方版本决定。
- 独立设置和管理中心托管设置使用同一能力判断；新增文案覆盖十个语言包。未修改共享控件工厂或管理中心公开桥接协议。

## 已完成验证

- 20 项 Lua 回归测试通过，包括新增 ForeverCompatibility_test.lua：客户端识别、配置迁移幂等性、原生点击目标、现代专精读取、设置视图、不可用内容预算、随机坐骑筛选及正式服回归。
- 27 个运行 Lua 文件语法检查通过。
- 五个 TOC 的文件引用、两项接口声明和 1.16.0 版本一致性检查通过。自动发布使用支持 Forever 的 BigWigs packager 2.7.0，并在上传前运行版本及包内容检查。
- 两项发布包回归测试通过；开发包使用独立文件名，置于忽略目录 `.release/`。
- 十个语言包新增文案键齐全；既有语言键差异保持原样。
- 已将开发包中的 129 个运行文件安装到 `D:/World of Warcraft/_forever_/Interface/AddOns`，全部 SHA256 与工作区一致。目标原先没有这些文件，本次覆盖数为零；安装清单为 `_backups/forever_20261105_151531/manifest.json`，玩家 SavedVariables 未改动。

## 游戏内验收

尚未完成真实客户端交互验证。同步后在无限版执行 `/reload`，依次确认：

1. `/qfxbar` 能打开，关闭管理中心时仍可独立设置；三个信息条能够分别启用和隐藏。
2. 天赋、法术书、传承按钮分别打开正确面板；专业、组队、收藏和冒险指南跟随该客户端实际可用功能。
3. 调整开关和拖动排序后 `/reload`，确认配置保留；反复重载不重复插入新按钮。
4. 信息条显示天赋名称，保存的天赋方案菜单能正常打开；有五项可用内容时不会被已隐藏的正式服内容挤掉。
5. 随机坐骑、指定坐骑、炉石以及所安装的第三方插件入口正常。
6. 战斗内按钮点击、战斗中修改设置及脱战应用均无错误；原生微型菜单的显示、隐藏和鼠标移入模式正常。

## 数据和回退

SavedVariables 声明保持 `QFXSystemBarDB`，不替换玩家 SavedVariables 文件。首次登录只补缺失的两个按钮字段和排序项。

同步备份位于工作区 `_backups/`，清单记录每个文件是否原已存在。回退时恢复清单中的已覆盖文件，仅移除清单标记为本次新增的文件，再执行 `/reload`；不要删除整个 AddOns 或 WTF 目录。开发包可重新安装；正式发布 ZIP 保持原样。
