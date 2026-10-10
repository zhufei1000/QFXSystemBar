#!/usr/bin/env python3
"""Build white MRT and Great Vault icons; see gen_white_icon.py."""
from gen_white_icon import build_white_icon

if __name__ == "__main__":
    for name in ("GreatVault", "MRT"):
        build_white_icon(name)
