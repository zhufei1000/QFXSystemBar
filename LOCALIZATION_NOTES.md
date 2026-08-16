# QFXSystemBar 本地化参考笔记（Localization Notes）

> **用途**：优化/翻译其他语言（frFR、esES、esMX、itIT、ptBR、koKR、zhCN、zhTW）时参考。
> **上次更新**：2026-08-17（v1.8.09，deDE / ruRU 已按此规范完成）

---

## 1. 信息条（Info Bar）显示项必须用短名（最重要）

信息条上每个显示项文本 = `UIText(labelKey)`（见 InfoBar.lua），条上最多显示 5 项、宽度有限。英文版通过 `Core.lua` 的 `englishOverrides` 表使用短名；**其他语言的 locale 必须直接提供当地玩家习惯的短名，不要用完整翻译**（如德语 "Gegenstandsstufe"、俄语 "Уровень предметов" 在条上放不下）。

### 必用短名的键（英 / 德 / 俄参考值）

| 英文键 | en | deDE | ruRU | 其他语言建议方向 |
|---|---|---|---|---|
| `Item Level` | iLvl | iLvl | iLvl | 直接用 iLvl（全球玩家共识） |
| `Mythic+ Score` | M+ | M+ | M+ | 用 M+（通用） |
| `Score` | M+ | Score | Скор | 当地玩家对"分数"的口语 |
| `Specialization` | Spec | Spec | Спека | 当地口语或英文借词 |
| `FPS / Latency` | FPS/MS | FPS/Ping | FPS/пинг | 延迟用 Ping/当地口语 |
| `Durability` | Dura | Dura | Прочка | 当地玩家口语 |
| `Location` | Zone | Zone | Локация | 短词（Zone/区域类） |
| `Coordinates` | Coords | Coords | Коорды | 当地口语 |
| `Phase ID` | Phase | Phase | Фаза | Phase 或当地短词 |
| `Advanced Combat Log` | ACL | ACL | ACL | 用 ACL（通用缩写） |
| `Combat Log` | ACL | ACL | ACL | 同 ACL |

### 注意事项
- 这些键**同时用于配置面板 "Displayed Information" 勾选项**，改短名后与英文版行为一致（英文版配置面板同样显示 iLvl/M+/Spec），是正确做法。
- **tooltip 完整说明**（如 "Show equipped item level." / "Показывает уровень надетых предметов."）保留完整翻译，不要缩短——tooltip 有空间。
- `Home Latency` / `World Latency` / `Latency` 不直接显示在条上，可保留完整翻译，但建议用玩家口语（如 Ping）。

---

## 2. 鼠标键简称——各国习惯不同，不要统一缩写

| 语言 | 左键 / 右键 / 中键 | 说明 |
|---|---|---|
| 俄语 ruRU | `ЛКМ` / `ПКМ` / `СКМ` | 俄语游戏社区标准缩写，**必须用缩写** |
| 德语 deDE | `Linksklick` / `Rechtsklick` / `Mittelklick` | 德语插件惯例用全称，不要强行缩写 |
| 英语 | Left Click / Right Click | 全称或 LMB/RMB |
| 中文 | 左键 / 右键 | 全称 |
| 其他 | — | 查询当地玩家论坛/社区确认，不要照搬俄语缩写 |

---

## 3. 术语本地化参考（deDE / ruRU 已确认符合魔兽玩家习惯）

### Housing（玩家住房，11.2.5+）
- 德语：用 **"Housing"**（社区普遍使用借词；暴雪官方 "Spielerbehausungen" 太长不适合按钮）
- 俄语：用 **"Жильё"**（官方/社区通用）
- 法语可参考：先查 fr 社区（一般也用借词 Housing）

### 德语已确认（保留）的官方/社区术语
`Ruhestein`(炉石) `Gruppensuche`(队伍查找器) `Erfolge`(成就) `Questlog`(任务日志) `Taschen`(背包) `Gegenstandsstufe`(装等) `Beutespezialisierung`(拾取专精) `Heimlatenz/Weltlatenz`(延迟) `Klassenfarbe`(职业颜色) `Abenteuerführer`(冒险指南) `Sammlungen`(收藏) `Spielmenü`(游戏菜单) `Wegpunkt`(路径点)

### 俄语已确认（保留）的官方/社区术语
`Камень возвращения`(炉石) `Поиск группы`(队伍查找器) `Достижения`(成就) `Журнал заданий`(任务日志) `Сумки`(背包) `Уровень предметов`(装等) `Специализация добычи`(拾取专精) `Коллекции`(收藏) `Путеводитель`(冒险指南) `Игровое меню`(游戏菜单) `Гильдия`(公会) `Прочность`(耐久·完整语境)

### 俄语口语化示例（比生硬翻译更符合玩家习惯）
| 英文键 | 生硬翻译 | 玩家习惯（已采用） |
|---|---|---|
| `Reload UI` | Перезагрузить интерфейс | **Релог** |
| `Create Waypoint` | Создать точку маршрута | **Создать вейпоинт** |
| `Toggle Bag Slots` | Переключить места в сумках | **Переключить ячейки сумок** |
| `Instance ID` | ID подземелья | **ID инстанса** |
| `My Position` | Моя позиция | **Мои координаты** |
| `Print ID` | Вывести ID | **Показать ID** |

---

## 4. 审计工作流（下次优化其他语言时使用）

1. **扫未翻译条目**：找 `["key"] = "value"` 中 `value == key` 的行（未翻译占位），长度 >8 且非专有名词（字体名/人名/图标集名如 Friz Quadrata、RoyRong、Game Icons）才需要处理。
2. **对比键集**：所有语言文件去重后的键集合应完全一致（当前 deDE/ruRU 各 **463** 键，frFR 等缺失键以此为准补齐）。
3. **语法检查**：Lua 括号/引号平衡。
4. **Info Bar 短名**：对照第 1 节表格，逐一确认短名。
5. **改完验证**：重新打包（15 个插件目录）→ 同步游戏 → 发布。

---

## 5. 各语言现状

| 语言 | 状态 |
|---|---|
| enUS/enGB | 基础（englishOverrides 提供短名） |
| deDE | ✅ 已审计修正（术语 6 处 + 短名） |
| ruRU | ✅ 已补全（217 处 + 85 缺失键 + 短名） |
| frFR | ⏳ **下一个优先**（欧服第三大语言区） |
| esES / esMX / itIT / ptBR / koKR / zhCN / zhTW | ⏳ 未审计，需按本文档流程处理 |
