# Phase 1: Playable Core

## Purpose

Create player movement, camera, interaction, clock, debug overlay, and versioned local save/load.

## Enhanced Features and Functions

- Keyboard/mouse and mobile input abstraction.
- Low-end camera profile.
- Interactable object prototype.
- World clock service.
- Atomic save with schema_version, checksum, and rotating backup.

## Core Deliverables

- Greybox scene.
- Player controller.
- Save manager.
- Debug overlay.
- Corrupt-save handling.

## Exit Gate

Player can move, interact, save, quit, reload, and recover safely from corrupt save data.

## Detailed Engineering Coverage

### Systems and Data to Cover

- Input layer must normalize keyboard, mouse, controller-target, and mobile touch actions.
- Player controller must separate movement, camera, interaction, and animation hooks.
- Save manager must write temp files, validate, then replace the active save atomically.
- Debug overlay must show FPS/frame time, quality preset, loaded zone, entity counts, and save version.

### Recommended Implementation Steps

1. Prototype movement in a tiny scene before adding town content.
2. Add interaction interface with one test object and one test pickup.
3. Create save migration function even for schema version 1.
4. Add corrupted-save fallback and backup restore path.

### Potential Issues to Troubleshoot

- Movement tied directly to desktop keys and impossible to reuse on mobile.
- Save file overwritten before validation.
- Frame rate displayed without frame time, hiding stutter.
- Debug overlay shipped on by default in release builds.

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
