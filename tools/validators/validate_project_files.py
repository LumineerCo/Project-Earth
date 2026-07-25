#!/usr/bin/env python3
"""Validate lightweight Godot project file references for Phase 1."""
from __future__ import annotations

import re
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
SCENE_PATH = ROOT / "game" / "scenes" / "main.tscn"
PROJECT_PATH = ROOT / "game" / "project.godot"
RESOURCE_RE = re.compile(r'path="res://([^"]+)"')


def main() -> int:
    errors: list[str] = []
    if not PROJECT_PATH.exists():
        errors.append(f"Missing {PROJECT_PATH}")
    if not SCENE_PATH.exists():
        errors.append(f"Missing {SCENE_PATH}")
    if SCENE_PATH.exists():
        text = SCENE_PATH.read_text(encoding="utf-8")
        for match in RESOURCE_RE.finditer(text):
            resolved = ROOT / "game" / match.group(1)
            if not resolved.exists():
                errors.append(f"{SCENE_PATH}: missing resource {match.group(0)} -> {resolved}")
    if PROJECT_PATH.exists() and 'run/main_scene="res://scenes/main.tscn"' not in PROJECT_PATH.read_text(encoding="utf-8"):
        errors.append(f"{PROJECT_PATH}: main scene must point to res://scenes/main.tscn")
    if errors:
        print("Project file validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print("Project scene/resource references validated.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
