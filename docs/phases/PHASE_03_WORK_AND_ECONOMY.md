# Phase 3: Work and Economy

## Purpose

Add legal jobs, inventory, shops, item prices, wages, and anti-duplication save behavior.

## Enhanced Features and Functions

- Wallet and inventory.
- Five starter jobs.
- Grocery/shop transactions.
- District price multipliers.
- Job reward idempotency checks.

## Core Deliverables

- Job board/phone jobs.
- Item catalog.
- Shop data.
- Economy manager.
- Reward audit events.

## Exit Gate

Player earns and spends money; shop inventory and district prices persist through save/load.

## Detailed Engineering Coverage

### Systems and Data to Cover

- Wallet transactions must be ledgered with reason, source, target, and timestamp.
- Jobs need acceptance, active, completion, reward-claimed, failed, and cooldown states.
- Shop inventories should reserve stock during transactions to prevent double purchase.
- District multipliers must be capped so prices do not become negative or absurd.

### Recommended Implementation Steps

1. Implement one delivery job first, then clone the pattern for other jobs.
2. Add item stack rules, weight/capacity hooks, and legal status field.
3. Add transaction IDs so rewards cannot be claimed twice after reload.
4. Add admin/debug economy view for balances, stock, and price multipliers.

### Potential Issues to Troubleshoot

- Save scumming duplicates rewards.
- Negative prices or wages from bad data.
- Shop inventory and player inventory fall out of sync.
- Inflation from adventure/business rewards destroys starter economy.

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
