# Phase 0: Foundation

## Purpose

Set up repository, Godot project, policies, validators, secret handling, and asset-license workflow.

## Enhanced Features and Functions

- Create Godot project under game/.
- Add .gitignore for Godot imports, exports, saves, .env, secret files.
- Create game/data folders for npc, schedules, items, jobs, districts, businesses, vehicles, events.
- Add first validator script for duplicate IDs and required fields.
- Document admin bootstrap using env var/local setup only.

## Core Deliverables

- Godot project shell.
- Sample data pack.
- Validator command.
- Secret-handling note.
- Asset-license workflow.

## Exit Gate

Repo opens cleanly; blank Android/desktop export path documented; validators pass; no plaintext secrets tracked.

## Detailed Engineering Coverage

### Systems and Data to Cover

- Repository hygiene: root docs, `game/`, `admin/`, `tools/`, `docs/`, and local-only save folders must have clear ownership.
- Godot version must be recorded before scenes are committed so imports remain stable.
- Secret policy must cover `.env`, local admin bootstrap files, generated export presets, crash logs, and screenshots.
- Asset policy must require license review before importing art, audio, map data, fonts, shaders, or scripts.

### Recommended Implementation Steps

1. Create root `.gitignore` before adding generated engine files.
2. Create minimal sample data first, then validate it before adding game code.
3. Add a `tools/validators` README explaining how validators should fail.
4. Record target Android export dependencies without requiring paid services.

### Potential Issues to Troubleshoot

- Generated `.godot/` or import cache committed accidentally.
- Admin bootstrap password copied into docs or fixtures.
- Sample data IDs chosen inconsistently and later hard to migrate.
- Asset downloaded from a free site but with unclear commercial or derivative permissions.

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
