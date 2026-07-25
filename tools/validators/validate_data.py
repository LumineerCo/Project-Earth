#!/usr/bin/env python3
"""Validate Project Earth Phase 0 data files.

This intentionally uses only the Python standard library so it works in the
zero-budget toolchain without installing dependencies.
"""
from __future__ import annotations

import json
import re
import sys
from collections import defaultdict
from pathlib import Path
from typing import Any

ROOT = Path(__file__).resolve().parents[2]
DATA_DIR = ROOT / "game" / "data"
TIME_RE = re.compile(r"^([01]\d|2[0-3]):[0-5]\d$")
SECRET_PATTERNS = ["Bablu" + "@" + "4151"]

REQUIRED_FIELDS = {
    "districts": {"id", "name", "type", "biome", "price_multiplier", "license"},
    "npcs": {"id", "display_name", "home_id", "workplace_id", "district_id", "role", "schedule_id", "wallet", "license"},
    "schedules": {"id", "entries", "license"},
    "items": {"id", "name", "category", "base_price", "weight_kg", "stack_limit", "legal_status", "license"},
    "jobs": {"id", "name", "category", "district_id", "base_reward", "cooldown_minutes", "stages", "license"},
    "locations": {"id", "name", "category", "district_id", "access", "license"},
    "businesses": {"id", "type", "display_name", "district_id", "owner_type", "owner_id", "employees", "open_hours", "inventory", "license"},
    "vehicles": {"id", "name", "category", "base_price", "fuel_type", "cargo_capacity_kg", "terrain_tags", "license"},
    "events": {"id", "name", "category", "district_id", "effects", "repeat_rule", "license"},
}


def load_json(path: Path) -> Any:
    try:
        return json.loads(path.read_text(encoding="utf-8"))
    except json.JSONDecodeError as exc:
        raise ValueError(f"{path}: invalid JSON: {exc}") from exc


def validate_required_fields(category: str, path: Path, data: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    missing = REQUIRED_FIELDS[category] - data.keys()
    if missing:
        errors.append(f"{path}: missing required fields: {', '.join(sorted(missing))}")
    if data.get("license") != "original":
        errors.append(f"{path}: Phase 0 sample data must be original or reviewed before import")
    return errors


def validate_values(category: str, path: Path, data: dict[str, Any]) -> list[str]:
    errors: list[str] = []
    if "id" in data and not isinstance(data["id"], str):
        errors.append(f"{path}: id must be a string")
    for field in ("base_price", "base_reward", "wallet", "cooldown_minutes", "price_multiplier", "cargo_capacity_kg"):
        if field in data and isinstance(data[field], (int, float)) and data[field] < 0:
            errors.append(f"{path}: {field} must not be negative")
    if category == "schedules":
        for index, entry in enumerate(data.get("entries", [])):
            if not TIME_RE.match(str(entry.get("start", ""))):
                errors.append(f"{path}: entries[{index}].start must be HH:MM 24-hour time")
            if not entry.get("action") or not entry.get("target"):
                errors.append(f"{path}: entries[{index}] requires action and target")
    if category == "businesses":
        hours = data.get("open_hours", {})
        for key in ("open", "close"):
            if not TIME_RE.match(str(hours.get(key, ""))):
                errors.append(f"{path}: open_hours.{key} must be HH:MM 24-hour time")
    return errors


def scan_for_secrets(path: Path) -> list[str]:
    text = path.read_text(encoding="utf-8", errors="ignore")
    return [f"{path}: contains forbidden secret pattern" for pattern in SECRET_PATTERNS if pattern in text]


def main() -> int:
    errors: list[str] = []
    ids: dict[str, Path] = {}
    by_category: dict[str, list[dict[str, Any]]] = defaultdict(list)

    if not DATA_DIR.exists():
        print(f"Data directory not found: {DATA_DIR}", file=sys.stderr)
        return 1

    for category, required in REQUIRED_FIELDS.items():
        category_dir = DATA_DIR / category
        if not category_dir.exists():
            errors.append(f"Missing data category directory: {category_dir}")
            continue
        for path in sorted(category_dir.glob("*.json")):
            errors.extend(scan_for_secrets(path))
            data = load_json(path)
            if not isinstance(data, dict):
                errors.append(f"{path}: root value must be an object")
                continue
            errors.extend(validate_required_fields(category, path, data))
            errors.extend(validate_values(category, path, data))
            entity_id = data.get("id")
            if isinstance(entity_id, str):
                if entity_id in ids:
                    errors.append(f"{path}: duplicate id {entity_id!r}; first seen at {ids[entity_id]}")
                ids[entity_id] = path
            by_category[category].append(data)

    known_ids = set(ids)
    for npc in by_category["npcs"]:
        for field in ("district_id", "schedule_id", "workplace_id"):
            if npc.get(field) not in known_ids:
                errors.append(f"NPC {npc.get('id')}: unknown {field} {npc.get(field)!r}")
        for item_id in npc.get("inventory", []):
            if item_id not in known_ids:
                errors.append(f"NPC {npc.get('id')}: unknown inventory item {item_id!r}")
    for district in by_category["districts"]:
        for service_id in district.get("services", []):
            if service_id not in known_ids:
                errors.append(f"District {district.get('id')}: unknown service {service_id!r}")
    for schedule in by_category["schedules"]:
        for index, entry in enumerate(schedule.get("entries", [])):
            if entry.get("target") not in known_ids:
                errors.append(f"Schedule {schedule.get('id')}: entries[{index}] unknown target {entry.get('target')!r}")
    for location in by_category["locations"]:
        if location.get("district_id") not in known_ids:
            errors.append(f"Location {location.get('id')}: unknown district_id {location.get('district_id')!r}")

    for business in by_category["businesses"]:
        for field in ("district_id", "owner_id"):
            if business.get(field) not in known_ids:
                errors.append(f"Business {business.get('id')}: unknown {field} {business.get(field)!r}")
        for employee_id in business.get("employees", []):
            if employee_id not in known_ids:
                errors.append(f"Business {business.get('id')}: unknown employee {employee_id!r}")
        for item_id in business.get("inventory", {}):
            if item_id not in known_ids:
                errors.append(f"Business {business.get('id')}: unknown inventory item {item_id!r}")
    for category in ("jobs", "events"):
        for entity in by_category[category]:
            if entity.get("district_id") not in known_ids:
                errors.append(f"{category[:-1].title()} {entity.get('id')}: unknown district_id {entity.get('district_id')!r}")

    if errors:
        print("Data validation failed:", file=sys.stderr)
        for error in errors:
            print(f"- {error}", file=sys.stderr)
        return 1

    print(f"Validated {len(ids)} data IDs across {len(REQUIRED_FIELDS)} categories.")
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
