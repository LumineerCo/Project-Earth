# Phase 4: Travel and Zones

## Purpose

Add streaming/travel between town, village/farm, and wilderness zones with vehicle and weather foundations.

## Enhanced Features and Functions

- Zone streaming/unloading.
- Bus stop or travel UI.
- Bicycle or motorbike ownership.
- Weather state.
- Spawn ownership rules per zone.

## Core Deliverables

- Town zone.
- Village/farm zone.
- Wilderness zone.
- Travel UI.
- Vehicle prototype.

## Exit Gate

Player repeatedly travels between three zones with no duplicate entities or corrupted saves.

## Detailed Engineering Coverage

### Systems and Data to Cover

- Zones must have stable IDs, entry points, spawn ownership, unload rules, and save restore positions.
- Travel UI must show cost, time, required vehicle/ticket, and risk/weather notices.
- Vehicle state includes owner, location, fuel/charge, condition, cargo, and parked state.
- Weather state must be global enough to affect schedules and local enough to vary by biome later.

### Recommended Implementation Steps

1. Implement loading transition first, then streaming improvements.
2. Track active zone and last safe position in saves.
3. Pool vehicles and NPCs instead of destroying/recreating blindly.
4. Test repeated town-village-wilderness travel loops.

### Potential Issues to Troubleshoot

- Duplicate NPCs, vehicles, or pickups after travel.
- Player loads inside blocked geometry.
- Inactive zones keep expensive simulation running.
- Owned vehicle lost when changing zones.

## Troubleshooting Checklist

- Confirm the phase does not introduce paid tools, paid services, or unlicensed assets.
- Confirm all new data is versioned, validated, and safe to load after save/load cycles.
- Confirm mobile performance is protected with density, LOD, pooling, or abstract simulation controls.
- Confirm admin/security-sensitive work keeps secrets out of Git, logs, client exports, and screenshots.
- Confirm failures produce useful debug messages rather than silent corruption.

## Engineering Notes

- Prefer data-driven configuration before hard-coded content.
- Keep the implementation small enough to demo at the phase gate.
- Add automated checks as soon as a data format or save format is introduced.
- Update `ASSET_LICENSES.md` before importing any third-party asset.
