# Phase 9: Admin and QA Hardening

## Purpose

Build admin observability, audit logs, validators, performance reports, save tests, and asset checks.

## Enhanced Features and Functions

- Local/self-hosted admin view.
- Role-based permissions.
- Audit log writes.
- Headless simulation/data tests.
- Performance profiles low/medium/high.

## Core Deliverables

- Admin dashboard.
- Audit log schema.
- Validator suite.
- Performance report template.
- No-secrets check.

## Exit Gate

Unauthorized actions fail; every mutation audits; validators pass; performance bottlenecks are reported.

## Detailed Engineering Coverage

### Systems and Data to Cover

- Admin actions require role, reason, target, before/after hash, timestamp, and audit ID.
- Validators must cover duplicate IDs, missing references, invalid schedules, invalid prices, missing licenses, and unsafe secrets.
- Performance reports must capture frame time, active NPCs, active vehicles, draw calls if available, memory, and quality preset.
- Save tests must cover migration, corrupt file, backup restore, and repeated save/load cycles.

### Recommended Implementation Steps

1. Build read-only admin screens before mutation actions.
2. Add mutation actions only after audit log exists.
3. Run headless or scripted simulation for seven in-game days.
4. Add no-secret scans to checks.

### Potential Issues to Troubleshoot

- Admin mutation without audit trail.
- Validator warnings ignored as non-blocking.
- Performance tested only on desktop high profile.
- Logs expose secrets or player-private data.

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
