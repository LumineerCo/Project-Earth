# Phase 7: Life Simulation Expansion

## Purpose

Deepen player needs, NPC relationships, housing, clothing comfort, and reputation without punishing casual play.

## Enhanced Features and Functions

- Needs presets.
- Relationship memory.
- Reputation channels.
- Housing comfort modifiers.
- Clothing/weather comfort rules.

## Core Deliverables

- Needs manager.
- Relationship UI.
- Reputation log.
- Housing upgrades.
- Casual-mode safeguards.

## Exit Gate

A full in-game week is playable with needs enabled; relationships and reputation affect NPC responses.

## Detailed Engineering Coverage

### Systems and Data to Cover

- Needs must support casual, normal, and realism presets with no hard fail in casual mode.
- Relationships need clear sources: conversation, help, harm, business satisfaction, gifts, debt, and witnessed behavior.
- Housing comfort affects rest quality, storage, hygiene access, and mood recovery.
- Clothing comfort responds to biome/weather but should not require constant micromanagement.

### Recommended Implementation Steps

1. Add needs as modifiers before adding severe penalties.
2. Expose relationship changes in UI feedback and NPC dialogue tone.
3. Add weekly cost summary so players understand bills.
4. Persist relationship history compactly to avoid save bloat.

### Potential Issues to Troubleshoot

- Needs drain too fast and block fun.
- Relationship data grows unbounded.
- NPCs react harshly without player-readable reason.
- Bills punish new players before income systems are stable.

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
