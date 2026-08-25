# -*- coding: utf-8 -*-
"""Dump the 85 keys missing from frFR, with deDE and ruRU reference values."""
import re
import io
import sys
import os

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

PATTERN = re.compile(r'^\s*\["((?:[^"\\]|\\.)*)"\]\s*=\s*"((?:[^"\\]|\\.)*)"', re.M)


def extract(path):
    with open(path, "r", encoding="utf-8") as f:
        content = f.read()
    out = {}
    for m in PATTERN.finditer(content):
        out[m.group(1)] = m.group(2)  # later entries win, matching Lua table semantics
    return out


def main():
    de = extract(os.path.join(ROOT, "QFXSystemBar_Locale_deDE", "deDE.lua"))
    ru = extract(os.path.join(ROOT, "QFXSystemBar_Locale_ruRU", "ruRU.lua"))
    fr = extract(os.path.join(ROOT, "QFXSystemBar_Locale_frFR", "frFR.lua"))

    missing = sorted(set(de) - set(fr))
    for k in missing:
        print("KEY: %s" % k)
        print("  de: %s" % de.get(k, "<none>"))
        print("  ru: %s" % ru.get(k, "<none>"))
        print()


if __name__ == "__main__":
    main()
