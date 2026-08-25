# -*- coding: utf-8 -*-
"""Compare locale key sets: deDE (reference) vs ruRU vs frFR."""
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
    return [(m.group(1), m.group(2)) for m in PATTERN.finditer(content)]


def main():
    de = extract(os.path.join(ROOT, "QFXSystemBar_Locale_deDE", "deDE.lua"))
    ru = extract(os.path.join(ROOT, "QFXSystemBar_Locale_ruRU", "ruRU.lua"))
    fr = extract(os.path.join(ROOT, "QFXSystemBar_Locale_frFR", "frFR.lua"))

    print("deDE entries: %d (unique %d)" % (len(de), len(set(k for k, _ in de))))
    print("ruRU entries: %d (unique %d)" % (len(ru), len(set(k for k, _ in ru))))
    print("frFR entries: %d (unique %d)" % (len(fr), len(set(k for k, _ in fr))))

    de_set = set(k for k, _ in de)
    ru_set = set(k for k, _ in ru)
    fr_set = set(k for k, _ in fr)

    print()
    print("in deDE not in frFR: %d" % len(de_set - fr_set))
    for k in sorted(de_set - fr_set):
        print("  MISSING -", k)
    print()
    print("in ruRU not in frFR: %d" % len(ru_set - fr_set))
    print("in frFR not in deDE: %d" % len(fr_set - de_set))
    for k in sorted(fr_set - de_set):
        print("  EXTRA   -", k)

    untr = [k for k, v in fr if k == v]
    print()
    print("frFR untranslated (value==key): %d" % len(untr))
    for k in untr:
        print("  SAME    -", k)


if __name__ == "__main__":
    main()
