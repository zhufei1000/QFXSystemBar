# -*- coding: utf-8 -*-
"""Compare locale key sets: deDE (reference) vs any target locales.

Usage:
    py -3 tests/cmp_locales.py                # default: all locales
    py -3 tests/cmp_locales.py zhCN zhTW      # specific locales
"""
import re
import io
import sys
import os
import glob

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

PATTERN = re.compile(r'^\s*\["((?:[^"\\]|\\.)*)"\]\s*=\s*"((?:[^"\\]|\\.)*)"', re.M)

# Proper nouns / brand names / identical loanwords that legitimately stay untranslated
LEGIT_SAME = {
    "Social", "General", "MeetingStone", "Collections", "Game Icons", "Lucide", "Tabler",
    "Friz Quadrata", "Arial Narrow", "Morpheus", "Skurri", "Chinese KaiTi",
    "Chinese KaiTi Bold", "Position", "QFXSystemBar", "ElvUI Wind",
    "RoyRong / siweia / fang2hou", "Menu", "Source", "Score", "Talents",
    "Total", "Volume", "Gold", "iLvl", "M+", "ACL", "Phase", "Zone", "Spec",
    "Coords", "Dura", "FPS/ping",
}


def extract(path):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    out = {}
    for m in PATTERN.finditer(content):
        out[m.group(1)] = m.group(2)  # later entries win, matching Lua table semantics
    return out


def locale_files():
    # Merged module layout: QFXSystemBar_Locale/<locale>.lua
    merged = os.path.join(ROOT, "QFXSystemBar_Locale", "*.lua")
    found = {}
    for path in sorted(glob.glob(merged)):
        name = os.path.splitext(os.path.basename(path))[0]
        found[name] = path
    if found:
        return found
    # Legacy layout: QFXSystemBar_Locale_<locale>/<locale>.lua
    for path in sorted(glob.glob(os.path.join(ROOT, "QFXSystemBar_Locale_*", "*.lua"))):
        name = os.path.splitext(os.path.basename(path))[0]
        found[name] = path
    return found


def main():
    targets = sys.argv[1:]
    files = locale_files()
    de = extract(files["deDE"])
    if not targets:
        targets = sorted(files)

    for name in targets:
        if name == "deDE":
            continue
        path = files.get(name)
        if not path:
            print("!! no locale file for %s" % name)
            continue
        data = extract(path)
        missing = set(de) - set(data)
        extra = set(data) - set(de)
        untr = [k for k, v in data.items() if k == v and k not in LEGIT_SAME]
        print("%s: %d unique keys | missing vs deDE: %d | extra: %d | untranslated: %d"
              % (name, len(data), len(missing), len(extra), len(untr)))
        for k in sorted(missing):
            print("   MISSING -", k)
        for k in sorted(untr):
            print("   SAME    -", k)
        print()


if __name__ == "__main__":
    main()
