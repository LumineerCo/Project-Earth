# Phase 2: Living Block

## Purpose

Build a small alive town block with persistent NPCs, homes, workplaces, and schedule-driven behavior.

## Enhanced Features and Functions

- Spawn persistent NPCs from data.
- Implement schedule archetypes.
- Use target-based movement before expensive pathfinding.
- Add off-screen abstract simulation.
- Persist NPC state and relationships.

## Core Deliverables

- Town block.
- 10 NPC records.
- 3 schedule archetypes.
- NPC debug list.
- Stuck NPC recovery rules.

## Exit Gate

10 NPCs complete two in-game days without permanent stuck states while debug/admin view reports actions.

## Detailed Engineering Coverage

### Systems and Data to Cover

- NPC state must include ID, home, role, schedule, current action, wallet, needs-lite, and relationship memory.
- Schedules need fallback actions for invalid routes, closed businesses, storms, or missing targets.
- Near NPCs use full animation/interaction; off-screen NPCs use schedule state only.
- Admin/debug view must explain why an NPC is doing an action.

### Recommended Implementation Steps

1. Start with 3 NPCs, then scale to 10 after schedules work.
2. Add route targets instead of expensive continuous path searches.
3. Add stuck detection with teleport-to-safe-point only after logging.
4. Simulate two in-game days as a repeatable test scenario.

### Potential Issues to Troubleshoot

- NPCs permanently stuck at doors or road edges.
- Every NPC ticking full AI every frame on mobile.
- Schedule data references missing locations.
- NPC duplicate spawns after save/load or zone reload.

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
