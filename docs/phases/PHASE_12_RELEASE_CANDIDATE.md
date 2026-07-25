# Phase 12: Release Candidate

## Purpose

Freeze scope, optimize, validate accessibility/licenses, package builds, and remove blockers.

## Enhanced Features and Functions

- LOD and texture optimization.
- Quality presets.
- Accessibility settings.
- License/credits screen.
- Android/desktop packaging.

## Core Deliverables

- Android build.
- Desktop build.
- Release checklist.
- Known issues doc.
- Final license audit.

## Exit Gate

Mobile targets 30 FPS, desktop targets 60 FPS, saves survive repeated cycles, and no critical blockers remain.

## Detailed Engineering Coverage

### Systems and Data to Cover

- Quality presets must tune resolution, shadows, texture quality, vegetation, NPC density, traffic density, draw distance, and effects.
- Accessibility must include subtitles, text scale, remapping target, low motion, audio sliders, and color-friendly UI.
- Release checklist must include save compatibility, license credits, admin secret scan, performance run, and known issues.
- Packaging must avoid debug credentials, test saves, local env files, and internal-only admin routes.

### Recommended Implementation Steps

1. Run repeated save/load cycles in all MVP zones.
2. Run low-end mobile and desktop profile performance passes.
3. Freeze content except blocker fixes.
4. Verify credits match `ASSET_LICENSES.md`.

### Potential Issues to Troubleshoot

- Debug tools exposed in public build.
- License attribution incomplete.
- Performance tuned on one device only.
- Last-minute content changes bypass validation.

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
