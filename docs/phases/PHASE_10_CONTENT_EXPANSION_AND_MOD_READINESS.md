# Phase 10: Content Expansion and Mod Readiness

## Purpose

Expand content while ensuring new districts, jobs, vehicles, and packs load via validated data.

## Enhanced Features and Functions

- Additional districts and villages.
- More jobs/businesses/vehicles.
- Content pack manifest.
- Asset import checklist.
- Safe mod boundary.

## Core Deliverables

- 3 town districts.
- 2 village variants.
- 2 wilderness POI sets.
- Content pack format.
- Import validator.

## Exit Gate

A content pack validates and loads without core-code changes, with useful errors for invalid references.

## Detailed Engineering Coverage

### Systems and Data to Cover

- Content packs need manifest ID, version, dependencies, assets, data tables, license references, and compatibility target.
- Import pipeline must enforce texture sizes, LODs, naming, collision settings, and attribution.
- New jobs/businesses/vehicles must be added through data templates when possible.
- Mod boundary must not allow arbitrary code execution in normal player installs.

### Recommended Implementation Steps

1. Add content validation before accepting new packs.
2. Create templates for district, job, business, vehicle, POI, and event.
3. Add useful validation errors with file path and ID.
4. Keep official content separate from community/local content.

### Potential Issues to Troubleshoot

- Mods or content packs can execute unsafe code.
- Asset attribution lost during import.
- Content density breaks mobile performance.
- New data formats bypass save migration rules.

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
