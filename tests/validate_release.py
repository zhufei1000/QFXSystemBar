"""Validate every bundled addon's release version and supported clients."""
import argparse
import re
from pathlib import Path

ROOT = Path(__file__).resolve().parent.parent
ADDONS = (
    "QFXSystemBar", "QFXSystemBar_Config", "QFXSystemBar_InfoBar",
    "QFXSystemBar_Locale", "QFXSystemBar_MeetingStone",
)
SUPPORTED_INTERFACES = {120105, 16001}


def validate_release(version):
    if not re.fullmatch(r"[0-9]+\.[0-9]+\.[0-9]+", version):
        raise ValueError(f"Invalid release version: {version}")
    for addon in ADDONS:
        folder = ROOT / addon
        toc = folder / f"{addon}.toc"
        lines = toc.read_text(encoding="utf-8-sig").splitlines()
        versions = [line.removeprefix("## Version:").strip() for line in lines if line.startswith("## Version:")]
        if versions != [version]:
            raise ValueError(f"{toc}: expected version {version}, got {versions}")
        declarations = [line for line in lines if line.startswith("## Interface")]
        if len(declarations) != 1 or not declarations[0].startswith("## Interface:"):
            raise ValueError(f"{toc}: expected exactly one shared interface declaration")
        interfaces = [int(value.strip()) for value in declarations[0].split(":", 1)[1].split(",")]
        if len(interfaces) != 2 or set(interfaces) != SUPPORTED_INTERFACES:
            raise ValueError(f"{toc}: expected only 120105 and 16001, got {interfaces}")
        if (folder / "addon_version.txt").read_text(encoding="utf-8-sig").strip() != version:
            raise ValueError(f"{addon}/addon_version.txt: version mismatch")
        for line in lines:
            line = line.strip()
            if line and not line.startswith("#"):
                if not (folder / line.replace("\\", "/")).is_file():
                    raise ValueError(f"{toc}: missing referenced file {line}")
    print(f"Validated {len(ADDONS)} addons: {version}; Retail 12.1.5 + Forever 1.60.1 only")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", default=(ROOT / "QFXSystemBar/addon_version.txt").read_text(encoding="utf-8-sig").strip())
    validate_release(parser.parse_args().version)
