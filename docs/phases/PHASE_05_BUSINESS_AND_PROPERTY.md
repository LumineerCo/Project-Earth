# Phase 5: Business and Property

## Purpose

Implement first player-owned business and basic housing/property state.

## Enhanced Features and Functions

- Food stall or grocery stall business.
- Stock purchase and pricing.
- Customer demand from NPC needs.
- Daily profit/loss summary.
- Rented room upgrades/storage.

## Core Deliverables

- Business dashboard.
- Customer simulation.
- Inventory stocking.
- Daily ledger.
- Property state.

## Exit Gate

Player stocks a business, sets prices, earns profit/loss, and retains state after travel and save/load.

## Detailed Engineering Coverage

### Systems and Data to Cover

- Business ledger must track stock purchases, sales, wages, rent, maintenance, theft/loss, and taxes/fees if enabled.
- Customer demand must come from NPC needs, district demand, time of day, price, and reputation.
- Property state must include owner/renter, storage, rent due, upgrades, and access permissions.
- Employee slots need schedule integration and wage cost.

### Recommended Implementation Steps

1. Start with one food/grocery stall only.
2. Add price multiplier limits and demand elasticity.
3. Add daily summary to phone and admin/debug view.
4. Persist business state across travel, sleep, and save/load.

### Potential Issues to Troubleshoot

- Business generates money while closed or unloaded incorrectly.
- Prices set to exploit values.
- NPC customers buy without stock being decremented.
- Rent/bills create unavoidable debt spiral for casual players.

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
