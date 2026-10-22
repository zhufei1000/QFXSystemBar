# -*- coding: utf-8 -*-
"""Build a development package; formal output paths must be selected explicitly."""
import argparse
import os
import sys
import zipfile
from pathlib import Path

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))

ADDON_DIRS = [
    "QFXSystemBar",
    "QFXSystemBar_Config",
    "QFXSystemBar_InfoBar",
    "QFXSystemBar_Locale",
    "QFXSystemBar_MeetingStone",
]


def is_runtime_file(path):
    """Keep source artwork for the generators without shipping it to the client."""
    path = Path(path)
    if path.suffix.lower() in {".png", ".svg", ".bak", ".tmp", ".log", ".pyc"}:
        return False
    if path.name.upper().startswith("CHANGELOG") or path.name == "AGENTS.md":
        return False
    if path.suffix.lower() == ".tga" and path.parent.name in {"GameIcons", "Lucide", "Tabler"} and path.with_suffix(".blp").is_file():
        return False
    return True


def build_package(out_path, overwrite=False):
    out_path = Path(out_path)
    if out_path.exists() and not overwrite:
        raise FileExistsError("Refusing to overwrite %s; choose another path or pass --overwrite." % out_path)
    out_path.parent.mkdir(parents=True, exist_ok=True)
    count = 0
    with zipfile.ZipFile(out_path, "w", zipfile.ZIP_DEFLATED) as z:
        for d in ADDON_DIRS:
            for base, _dirs, files in os.walk(os.path.join(ROOT, d)):
                for name in sorted(files):
                    full = os.path.join(base, name)
                    if not is_runtime_file(full):
                        continue
                    rel = os.path.relpath(full, ROOT).replace(os.sep, "/")
                    z.write(full, rel)
                    count += 1
    return count, out_path.stat().st_size


def main():
    if hasattr(sys.stdout, "reconfigure"):
        sys.stdout.reconfigure(encoding="utf-8", errors="replace")
    version = Path(ROOT, "QFXSystemBar", "addon_version.txt").read_text(encoding="utf-8").strip()
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--output", type=Path, default=Path(ROOT, ".release", "QFXSystemBar_%s_dev.zip" % version))
    parser.add_argument("--overwrite", action="store_true")
    args = parser.parse_args()
    count, size = build_package(args.output, args.overwrite)
    print("built %s (%d files, %.1f KB)" % (args.output, count, size / 1024.0))


if __name__ == "__main__":
    main()
