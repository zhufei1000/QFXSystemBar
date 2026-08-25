# -*- coding: utf-8 -*-
"""One-shot helper: add frFR column to LOCALIZATION_NOTES.md short-name table."""
import os

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
path = os.path.join(ROOT, "LOCALIZATION_NOTES.md")

with open(path, encoding="utf-8") as f:
    content = f.read()

pairs = [
    ("### 必用短名的键（英 / 德 / 俄参考值）", "### 必用短名的键（英 / 德 / 俄 / 法参考值）"),
    ("| 英文键 | en | deDE | ruRU | 其他语言建议方向 |\n|---|---|---|---|---|",
     "| 英文键 | en | deDE | ruRU | frFR | 其他语言建议方向 |\n|---|---|---|---|---|---|"),
    ("| `Item Level` | iLvl | iLvl | iLvl | 直接用", "| `Item Level` | iLvl | iLvl | iLvl | iLvl | 直接用"),
    ("| `Mythic+ Score` | M+ | M+ | M+ | 用 M+", "| `Mythic+ Score` | M+ | M+ | M+ | M+ | 用 M+"),
    ("Скор | 当地玩家对", "Скор | Score | 当地玩家对"),
    ("Спека | 当地口语或英文借词", "Спека | Spé | 当地口语或英文借词"),
    ("FPS/пинг | 延迟用", "FPS/пинг | FPS/ping | 延迟用"),
    ("Прочка | 当地玩家口语", "Прочка | Dura | 当地玩家口语"),
    ("Локация | 短词", "Локация | Zone | 短词"),
    ("Коорды | 当地口语", "Коорды | Coords | 当地口语"),
    ("Фаза | Phase 或当地短词", "Фаза | Phase | Phase 或当地短词"),
    ("| `Advanced Combat Log` | ACL | ACL | ACL | 用 ACL", "| `Advanced Combat Log` | ACL | ACL | ACL | ACL | 用 ACL"),
    ("| `Combat Log` | ACL | ACL | ACL | 同 ACL |",
     "| `Combat Log` | ACL | ACL | ACL | ACL | 同 ACL |\n"
     "| `Vol`（音量项短标签） | Vol | Lautst. | Звук | Son | 当地口语；⚠️ 法语 \"Vol\" 意为\"飞行\"，不可用 |\n"
     "| `Muted` | Muted | Stumm | Без звука | Muet | — |"),
]

for old, new in pairs:
    assert old in content, "not found: " + old[:50]
    content = content.replace(old, new, 1)

with open(path, "w", encoding="utf-8", newline="") as f:
    f.write(content)
print("notes table updated OK")
