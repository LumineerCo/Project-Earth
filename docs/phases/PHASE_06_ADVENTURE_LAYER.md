# Phase 6: Adventure Layer

## Purpose

Add wilderness exploration, repeatable POIs, safe hazards, resource rewards, and adventure log.

## Enhanced Features and Functions

- Cave/ruin greybox.
- Exploration event table.
- Weather/stamina/navigation hazards.
- Resource collection.
- Reward caps.

## Core Deliverables

- Adventure log.
- 5 exploration events.
- 3 resource types.
- Hazard controller.
- Balanced reward table.

## Exit Gate

Player completes exploration, returns safely, and rewards remain balanced against economy income.

## Detailed Engineering Coverage

### Systems and Data to Cover

- POIs need discovered/undiscovered, cleared/repeatable, danger level, reward table, and cooldown state.
- Hazards should be readable and recoverable, not random unavoidable punishment.
- Rewards must include non-cash options such as reputation, knowledge, crafting resources, photos, or unlocks.
- Adventure log must record clues, discoveries, current risk, and return route.

### Recommended Implementation Steps

1. Build one cave/ruin path with clear exit before branching content.
2. Add hazard warnings through weather, UI, NPC advice, or environment cues.
3. Cap high-value rewards and add cooldowns.
4. Save POI state before and after reward claims.

### Potential Issues to Troubleshoot

- Player gets trapped without a return path.
- Exploration rewards overpower jobs/businesses.
- Repeatable POIs duplicate unique items.
- Hazards are invisible or feel unfair.

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
