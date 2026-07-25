# Phase 11: Online Optional Operations

## Purpose

Keep offline-first gameplay while preparing optional self-hosted backend, backups, moderation, and privacy workflows.

## Enhanced Features and Functions

- Self-hosted architecture.
- Cloud-save interface abstraction.
- Backup/restore flow.
- Moderation workflow.
- Privacy export/delete.

## Core Deliverables

- Offline mode checks.
- Backend architecture note.
- Backup checklist.
- Moderation notes.
- Privacy workflow.

## Exit Gate

Network-disabled gameplay remains complete; optional services store no plaintext secrets and pass restore tests.

## Detailed Engineering Coverage

### Systems and Data to Cover

- Offline mode remains complete and must not require account login.
- Online services are optional, self-hostable, and replaceable with local stubs.
- Backups need version, timestamp, checksum, encryption plan if sensitive, and restore test.
- Moderation workflows need reports, warnings, bans, appeal notes, and audit logs.

### Recommended Implementation Steps

1. Design interfaces so cloud saves can be disabled.
2. Document self-hosted deployment without paid-only dependencies.
3. Add privacy export/delete flow before collecting online data.
4. Separate admin credentials from player accounts.

### Potential Issues to Troubleshoot

- Core gameplay accidentally depends on network.
- Free hosting limits cause data loss or lockout.
- Backups cannot be restored.
- Moderation actions lack audit or appeal trail.

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
