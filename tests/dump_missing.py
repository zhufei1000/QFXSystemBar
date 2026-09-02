# -*- coding: utf-8 -*-
"""Dump keys missing from a locale, with deDE and ruRU reference values.

Usage:
    py -3 tests/dump_missing.py          # default: itIT
    py -3 tests/dump_missing.py koKR     # explicit target locale
"""
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
    locale_dir = os.path.join(ROOT, "QFXSystemBar_Locale")
    target = sys.argv[1] if len(sys.argv) > 1 else "itIT"
    de = extract(os.path.join(locale_dir, "deDE.lua"))
    ru = extract(os.path.join(locale_dir, "ruRU.lua"))
    target_values = extract(os.path.join(locale_dir, target + ".lua"))

    missing = sorted(set(de) - set(target_values))
    for k in missing:
        print("KEY: %s" % k)
        print("  de: %s" % de.get(k, "<none>"))
        print("  ru: %s" % ru.get(k, "<none>"))
        print()


if __name__ == "__main__":
    main()
