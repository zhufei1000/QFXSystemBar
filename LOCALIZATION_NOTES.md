# QFXSystemBar 本地化参考笔记（Localization Notes）

> **用途**：优化/翻译其他语言（esES、esMX、itIT、ptBR、koKR、zhCN、zhTW）时参考。
> **上次更新**：2026-08-25（v1.8.10，frFR 已按此规范完成；deDE / ruRU 此前已完成）

---

## 1. 信息条（Info Bar）显示项必须用短名（最重要）

信息条上每个显示项文本 = `UIText(labelKey)`（见 InfoBar.lua），条上最多显示 5 项、宽度有限。英文版通过 `Core.lua` 的 `englishOverrides` 表使用短名；**其他语言的 locale 必须直接提供当地玩家习惯的短名，不要用完整翻译**（如德语 "Gegenstandsstufe"、俄语 "Уровень предметов" 在条上放不下）。

### 必用短名的键（英 / 德 / 俄 / 法参考值）

| 英文键 | en | deDE | ruRU | frFR | 其他语言建议方向 |
|---|---|---|---|---|---|
| `Item Level` | iLvl | iLvl | iLvl | iLvl | 直接用 iLvl（全球玩家共识） |
| `Mythic+ Score` | M+ | M+ | M+ | M+ | 用 M+（通用） |
| `Score` | M+ | Score | Скор | Score | 当地玩家对"分数"的口语 |
| `Specialization` | Spec | Spec | Спека | Spé | 当地口语或英文借词 |
| `FPS / Latency` | FPS/MS | FPS/Ping | FPS/пинг | FPS/ping | 延迟用 Ping/当地口语 |
| `Durability` | Dura | Dura | Прочка | Dura | 当地玩家口语 |
| `Location` | Zone | Zone | Локация | Zone | 短词（Zone/区域类） |
| `Coordinates` | Coords | Coords | Коорды | Coords | 当地口语 |
| `Phase ID` | Phase | Phase | Фаза | Phase | Phase 或当地短词 |
| `Advanced Combat Log` | ACL | ACL | ACL | ACL | 用 ACL（通用缩写） |
| `Combat Log` | ACL | ACL | ACL | ACL | 同 ACL |
| `Vol`（音量项短标签） | Vol | Lautst. | Звук | Son | 当地口语；⚠️ 法语 "Vol" 意为"飞行"，不可用 |
| `Muted` | Muted | Stumm | Без звука | Muet | — |

### 注意事项
- 这些键**同时用于配置面板 "Displayed Information" 勾选项**，改短名后与英文版行为一致（英文版配置面板同样显示 iLvl/M+/Spec），是正确做法。
- **tooltip 完整说明**（如 "Show equipped item level." / "Показывает уровень надетых предметов."）保留完整翻译，不要缩短——tooltip 有空间。
- `Home Latency` / `World Latency` / `Latency` 不直接显示在条上，可保留完整翻译，但建议用玩家口语（如 Ping）。

### 1b. 英文 KEY 本身太长也会溢出（Core.lua englishOverrides）

英文源 KEY 直接作为英文界面的 fallback 显示文本，太长同样溢出。处理机制在 **Core.lua 的两个表**（仅影响英文显示，不影响 locale/SavedVariables）：
- `englishOverrides`（约 L233）：主覆盖
- `englishShortDescriptionOverrides`（约 L370）：紧凑覆盖，合并进主表；两个表合计 **319 条**

**审计规则**（2026-08-17 已按此补齐 38 条）：
1. 收集全部英文 KEY（以 deDE 键集为准，463 个）减去两个覆盖表的 key → 未覆盖列表
2. 未覆盖中**名词短语类**（选项名/下拉值/标签，如 `Class Color: Icons Only`、`Right Click: Dalaran Hearthstone`）必须补短名
3. **动词开头描述句**（Show/Choose/Adjust/Controls...开头）显示在 tooltip，有空间，不补
4. 语言名（Simplified Chinese 等）、人名、字体名、品牌名保留原文

已补充的英文短名示例：`Class Color: Icons Only`→"Icons Only"、`Right Click: Dalaran Hearthstone`→"Right: Dalaran HS"、`Blizzard Native Micro Menu`→"Native Menu"、`Fade except time`→"Fade, Keep Time"、`Outer Top and Bottom Lines`→"Outer Lines"、`Show Online Guild Members`→"Show Guild Online"。

> ⚠️ 改动 Core.lua 后：同步游戏内 `QFXSystemBar/Core.lua`；已发布的 zip 不要覆盖（下次发版自然包含）。

---

## 2. 鼠标键简称——各国习惯不同，不要统一缩写

| 语言 | 左键 / 右键 / 中键 | 说明 |
|---|---|---|
| 俄语 ruRU | `ЛКМ` / `ПКМ` / `СКМ` | 俄语游戏社区标准缩写，**必须用缩写** |
| 德语 deDE | `Linksklick` / `Rechtsklick` / `Mittelklick` | 德语插件惯例用全称，不要强行缩写 |
| 法语 frFR | `Clic gauche` / `Clic droit` / `Clic milieu` | 法语 UI 标准全称，不用缩写 |
| 英语 | Left Click / Right Click | 全称或 LMB/RMB |
| 中文 | 左键 / 右键 | 全称 |
| 其他 | — | 查询当地玩家论坛/社区确认，不要照搬俄语缩写 |

---

## 3. 术语本地化参考（deDE / ruRU / frFR 已确认符合魔兽玩家习惯）

### Housing（玩家住房，11.2.5+）
- 德语：用 **"Housing"**（社区普遍使用借词；暴雪官方 "Spielerbehausungen" 太长不适合按钮）
- 俄语：用 **"Жильё"**（官方/社区通用）
- 法语：用 **"Logis"**（暴雪法语官方译名，11.2.7 起社区/JudgeHype 均用此词；不要用 "Logement/Habitation"）

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

### 法语已确认（保留）的官方/社区术语
`Pierre de foyer`(炉石) `Recherche de groupe`(队伍查找器) `Hauts faits`(成就) `Journal de quêtes`(任务日志) `Sacs`(背包) `Niveau d'objet`(装等·完整语境) `Spécialisation de butin`(拾取专精) `Collections`(收藏) `Guide de l'aventurier`(冒险指南) `Menu du jeu`(游戏菜单) `Guilde`(公会) `Durabilité`(耐久·完整语境) `Logis`(住房) `point de repère`(路径点·11.0 起官方/社区通用) `Mythique+`(大秘境) `Métiers`(专业) `Grimoire`(法术书)

### 法语口语化示例（比生硬翻译更符合玩家习惯）
| 英文键 | 生硬翻译 | 玩家习惯（已采用） |
|---|---|---|
| `Specialization` | Spécialisation | **Spé**（条上短名） |
| `Vol`（音量短标签） | Vol（=飞行，歧义） | **Son** |
| `Muted` | En sourdine | **Muet** |
| `Toggle Mute` | Basculer la sourdine | **Activer/Désactiver le son** |
| `Durability` | Durabilité | **Dura**（条上短名） |

### 西班牙语已确认（保留）的官方/社区术语
`Piedra de hogar`(炉石) `Buscador de grupo`(队伍查找器) `Logros`(成就) `Registro de misiones`(任务日志) `Bolsas`(背包) `Nivel de objeto`(装等·完整语境) `Especialización de botín`(拾取专精) `Colecciones`(收藏) `Guía de aventuras`(冒险指南) `Menú del juego`(游戏菜单) `Hermandad`(公会) `Durabilidad`(耐久·完整语境) `Vivienda`(住房·11.2.7 官方) `punto de ruta`(路径点·官方) `Mítica+`(大秘境) `Profesiones`(专业) `Libro de hechizos`(法术书)

### 西班牙语口语化示例
| 英文键 | 生硬翻译 | 玩家习惯（已采用） |
|---|---|---|
| `Specialization` | Especialización | **Espec.**（条上短名） |
| `Durability` | Durabilidad | **Dura**（条上短名） |
| `Muted` | Silenciado | **Mudo** |
| `Location` | Ubicación | **Zona**（条上短名） |

esES 与 esMX 文案共用（暴雪及插件社区惯例，本文案无 vosotros/ustedes 分歧点），两文件仅 RegisterLocale 的语言码不同。

---

## 4. 审计工作流（下次优化其他语言时使用）

1. **扫未翻译条目**：找 `["key"] = "value"` 中 `value == key` 的行（未翻译占位），长度 >8 且非专有名词（字体名/人名/图标集名如 Friz Quadrata、RoyRong、Game Icons）才需要处理。
2. **对比键集**：所有语言文件去重后的键集合应完全一致（当前 deDE/ruRU/frFR/esES/esMX/zhCN/zhTW 各 **463** 键，其他语言缺失键以此为准补齐）。
3. **语法检查**：Lua 括号/引号平衡。
4. **Info Bar 短名**：对照第 1 节表格，逐一确认短名。
5. **改完验证**：重新打包（5 个插件目录）→ 同步游戏 → 发布。

### 目录结构（1.8.12 起合并）

2026-08-25 起，10 个 `QFXSystemBar_Locale_<lang>/` 子插件合并为单一 **`QFXSystemBar_Locale/`** 模块（`## LoadOnDemand: 1`，依赖主插件），内含 `<lang>.lua` × 10。加载逻辑在 Core.lua `EnsureLocaleLoaded`：优先加载合并模块，失败时回退旧的 `QFXSystemBar_Locale_<locale>` 命名（兼容未清理的旧安装）。**新增语言 = 在该目录加 `<lang>.lua` + 在 toc 文件列表追加一行**，无需再建子插件目录。

---

## 5. 各语言现状

| 语言 | 状态 |
|---|---|
| enUS/enGB | 基础（englishOverrides 提供短名） |
| deDE | ✅ 已审计修正（术语 6 处 + 短名） |
| ruRU | ✅ 已补全（217 处 + 85 缺失键 + 短名；Credits/Mythic+ 两个键留英，可后续润色） |
| frFR | ✅ 已补全（2026-08-25：85 缺失键 + 全部占位翻译 + 短名 + Housing→Logis / waypoint→point de repère 术语修正；463 键对齐） |
| esES / esMX | ✅ 已补全（2026-08-25：85 缺失键 + 全部占位翻译 + 短名 + Vivienda / punto de ruta 官方术语；两文件共用文案） |
| zhCN / zhTW | ✅ 原生维护，2026-08-25 补齐最后 1 个缺失键（音量提示） |
| itIT / koKR / ptBR | ⏳ 未审计（各缺 85 键 + 79 条占位），需按本文档流程处理；优先级 ptBR > koKR > itIT |

> 辅助脚本：`tests/cmp_locales.py`（键集对比+未翻译扫描，支持合并目录与旧目录布局）、`tests/dump_missing.py`（列出缺失键及 de/ru 参考译文）、`tests/build_release_zip.py`（本地打包 5 个插件目录），审计其他语言时可直接复用。
>
> **结构变更（1.8.12 起）**：10 个 locale 子插件合并为 `QFXSystemBar_Locale/` 单模块（见第 4 节）。发布后玩家若残留旧的 `QFXSystemBar_Locale_*` 目录不影响运行（旧模块仍可独立注册），但建议在更新说明里提示删除。
