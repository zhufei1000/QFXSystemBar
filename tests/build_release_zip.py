# -*- coding: utf-8 -*-
"""Build the QFXSystemBar release zip (14 addon dirs at zip top level)."""
import os
import sys
import io
import zipfile

sys.stdout = io.TextIOWrapper(sys.stdout.buffer, encoding="utf-8", errors="replace")
ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

ADDON_DIRS = [
    "QFXSystemBar",
    "QFXSystemBar_Config",
    "QFXSystemBar_InfoBar",
    "QFXSystemBar_Locale",
    "QFXSystemBar_MeetingStone",
]


def main():
    version = open(os.path.join(ROOT, "QFXSystemBar", "addon_version.txt"), encoding="utf-8").read().strip()
    out_path = os.path.join(ROOT, "QFXSystemBar_%s.zip" % version)
    count = 0
    with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as z:
        for d in ADDON_DIRS:
            for base, _dirs, files in os.walk(os.path.join(ROOT, d)):
                for name in sorted(files):
                    full = os.path.join(base, name)
                    rel = os.path.relpath(full, ROOT).replace(os.sep, "/")
                    z.write(full, rel)
                    count += 1
    size = os.path.getsize(out_path)
    print("built %s (%d files, %.1f KB)" % (os.path.basename(out_path), count, size / 1024.0))


if __name__ == "__main__":
    main()
