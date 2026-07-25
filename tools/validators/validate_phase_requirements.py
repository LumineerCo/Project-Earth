#!/usr/bin/env python3
"""Validate phase acceptance requirements that span multiple data files."""
from __future__ import annotations

import json
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "game" / "data"


def load_all(category: str) -> list[dict]:
    return [json.loads(path.read_text(encoding="utf-8")) for path in sorted((DATA_DIR / category).glob("*.json"))]


def main() -> int:
    errors: list[str] = []
    npcs = load_all("npcs")
    schedules = load_all("schedules")
    schedule_ids = {schedule["id"] for schedule in schedules}
    if len(npcs) < 10:
        errors.append(f"Phase 2 requires at least 10 persistent NPCs; found {len(npcs)}")
    if len(schedule_ids) < 3:
        errors.append(f"Phase 2 requires at least 3 schedule archetypes; found {len(schedule_ids)}")
    used_schedules = {npc.get("schedule_id") for npc in npcs}
    if len(used_schedules & schedule_ids) < 3:
        errors.append("Phase 2 NPCs must use at least 3 valid schedule archetypes")
    missing_schedule_npcs = [npc.get("id", "<unknown>") for npc in npcs if npc.get("schedule_id") not in schedule_ids]
    if missing_schedule_npcs:
        errors.append("NPCs reference missing schedules: " + ", ".join(missing_schedule_npcs))
    if errors:
        print("Phase requirement validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1
    print(f"Phase 2 requirements validated: {len(npcs)} NPCs across {len(schedule_ids)} schedules.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
