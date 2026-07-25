# Project Earth Engineering Plan

## 1. Purpose

This engineering plan converts the Game Design Document into implementation-ready technical decisions for a zero-budget, free/open-source Project Earth prototype. It focuses on building a stable MVP first, avoiding scope explosion, protecting admin access, and keeping the game smooth on mobile and desktop hardware.

## 2. Engineering Principles

1. **Prototype small, scale later:** Build one town, one village, and one wilderness zone before attempting a full planet-scale world.
2. **Data-driven systems:** NPCs, jobs, shops, vehicles, items, events, and districts should be defined in data files so designers can add content without rewriting engine code.
3. **Deterministic simulation where possible:** Use seeded random generation and event logs so saves remain debuggable and admin tools can reproduce world state.
4. **Offline-first:** The first release must work without paid servers. Online services are optional and must support self-hosting.
5. **Security by design:** Admin credentials and secrets must never be stored in plaintext in the repository or client build.
6. **Performance budgets are features:** Every system must define a mobile-safe budget before visual polish is added.

## 3. Recommended Repository Structure

```text
Project-Earth/
├── README.md
├── ASSET_LICENSES.md
├── docs/
│   ├── GDD.md
│   └── ENGINEERING_PLAN.md
├── game/
│   ├── project.godot
│   ├── scenes/
│   ├── scripts/
│   ├── assets/
│   ├── data/
│   └── tests/
├── admin/
│   ├── README.md
│   ├── src/
│   └── tests/
├── tools/
│   ├── importers/
│   ├── validators/
│   └── build/
└── saves_dev/
```

The `saves_dev/` directory should be ignored by Git once created because it may contain local player/admin test data.

## 4. Module Breakdown

| Module | Responsibility | MVP priority |
| --- | --- | --- |
| Device Quality Manager | Detect device class and set graphics/simulation budgets | High |
| World Streaming Manager | Load/unload districts, interiors, roads, and wilderness chunks | High |
| Player Controller | Movement, camera, interactions, mobile/PC input | High |
| Time and Weather Manager | Day/night, schedules, storms, seasonal hooks | High |
| NPC Scheduler | Daily routines, jobs, homes, needs, simple memory | High |
| Economy Manager | Prices, wages, inventory supply, shop transactions | High |
| Job System | Delivery, farm helper, shop assistant, taxi, courier | High |
| Save System | Versioned local save/load and migrations | High |
| Admin Data Bridge | Development/admin read APIs for safe local inspection | High |
| Vehicle System | Basic ownership, fuel/charge, damage, parking | Medium |
| Business System | Player shop/farm setup, employees, stock, pricing | Medium |
| Quest/Event System | Scripted and dynamic tasks | Medium |
| Law System | Traffic/crime reports, fines, police response | Medium |
| Build/Property System | Housing, rent, land ownership, decoration | Low for MVP |
| Multiplayer Sync | Optional future work only | Deferred |

## 5. Data-Driven Content Model

Use readable data files during early development. JSON is simple, but Godot resources or SQLite can be introduced once schemas stabilize.

### 5.1 NPC Schema Draft

```json
{
  "id": "npc_town_001",
  "display_name": "Asha Verma",
  "home_id": "home_old_market_03",
  "workplace_id": "shop_grocery_01",
  "role": "shop_assistant",
  "personality_tags": ["friendly", "careful"],
  "skills": { "trading": 2, "cooking": 1 },
  "wallet": 850,
  "needs": { "hunger": 35, "energy": 80, "mood": 60 },
  "schedule_id": "schedule_shop_assistant_day",
  "relationship_memory": {},
  "inventory": ["item_phone_basic", "item_lunch_box"]
}
```

### 5.2 Schedule Schema Draft

```json
{
  "id": "schedule_shop_assistant_day",
  "entries": [
    { "start": "06:30", "action": "travel", "target": "shop_grocery_01" },
    { "start": "08:00", "action": "work", "target": "shop_grocery_01" },
    { "start": "12:30", "action": "lunch", "target": "market_food_stall_02" },
    { "start": "17:30", "action": "travel", "target": "home_old_market_03" },
    { "start": "22:30", "action": "sleep", "target": "home_old_market_03" }
  ]
}
```

### 5.3 Item Schema Draft

```json
{
  "id": "item_rice_bag_small",
  "name": "Small Rice Bag",
  "category": "food",
  "base_price": 120,
  "weight_kg": 5,
  "stack_limit": 10,
  "legal_status": "legal",
  "license": "original"
}
```

### 5.4 Business Schema Draft

```json
{
  "id": "business_grocery_01",
  "type": "grocery_store",
  "district_id": "old_market",
  "owner_type": "npc",
  "owner_id": "npc_town_010",
  "employees": ["npc_town_001"],
  "open_hours": { "open": "08:00", "close": "21:00" },
  "inventory": { "item_rice_bag_small": 40 },
  "price_multiplier": 1.08,
  "reputation": 55
}
```

## 6. Save System Design

Each save file should include:

- Save format version.
- Player state.
- World clock and weather state.
- Active event IDs.
- Modified entity states only; unmodified base content can be reloaded from data files.
- Migration history.
- Checksum to detect corruption.

Recommended save flow:

1. Write save data to a temporary file.
2. Validate required fields.
3. Write checksum.
4. Atomically replace the previous save.
5. Keep one rotating backup save.

## 7. Admin Panel and Data Access

### 7.1 Credential Handling

The required default admin username is `BabluKSahu`. The initial password must be supplied through a local setup flow or environment variable such as `PROJECT_EARTH_ADMIN_BOOTSTRAP_PASSWORD`, hashed immediately, then removed from runtime memory where practical. The plaintext password must not be committed to the repository, sent to the game client, or printed in logs.

### 7.2 Admin Roles

| Role | Capabilities |
| --- | --- |
| Owner | Full access, role management, backup/restore, economy corrections |
| Moderator | User warnings, bans, reports, support notes |
| Economy Admin | Prices, jobs, business corrections, fraud review |
| World Admin | Events, NPC inspection, world health |
| Read-only Auditor | View logs and metrics without mutation |

### 7.3 Audit Log Fields

```json
{
  "audit_id": "audit_2026_000001",
  "timestamp_utc": "2026-07-25T00:00:00Z",
  "actor_user_id": "admin_babluksahu",
  "actor_role": "owner",
  "action": "adjust_player_currency",
  "target_type": "player_profile",
  "target_id": "player_001",
  "before_hash": "sha256:...",
  "after_hash": "sha256:...",
  "reason": "Support correction",
  "ip_hash": "sha256:..."
}
```

## 8. Performance Budgets

| System | Low-end mobile budget | Desktop budget |
| --- | --- | --- |
| Visible high-detail NPCs | 20-35 | 100-200 |
| Active vehicles | 10-20 | 60-120 |
| Full AI tick | 4-10 Hz | 10-30 Hz |
| Distant economy tick | Every 5-30 simulated minutes | Every 1-10 simulated minutes |
| Draw distance | 250-600 m | 1000-3000 m |
| Shadow casters | Player + key lights only | Multiple local lights |
| Texture target | 512-1024 px atlased | 1024-2048 px atlased |

If frame time exceeds target for more than 5 seconds, the device quality manager should reduce density before reducing core gameplay functionality.

## 9. Testing Strategy

| Test type | Purpose | Example |
| --- | --- | --- |
| Data validation | Prevent broken NPC/job/item definitions | Check all referenced IDs exist |
| Save migration tests | Protect player saves across updates | Load old save versions and compare state |
| Performance tests | Prevent mobile regressions | Spawn MVP town and measure frame time |
| Simulation tests | Keep economy/NPC schedules consistent | Run 7 simulated days headless |
| Admin security tests | Prevent unauthorized actions | Verify role permissions and audit logs |
| License checks | Avoid illegal asset usage | Validate every imported asset has license metadata |

## 10. MVP Acceptance Checklist

- Player can move, interact, save, load, and travel between three MVP zones.
- At least 30 persistent NPCs follow schedules and appear at correct jobs/homes.
- At least five jobs pay money and update player skill/reputation.
- At least two businesses can be operated by the player.
- Economy prices change by district, supply, and demand.
- Admin panel can inspect users, NPCs, economy, events, and audit logs.
- Low-end mobile profile maintains the target frame rate with reduced density.
- Every imported asset has an entry in `ASSET_LICENSES.md`.

## 11. Immediate Engineering Tasks

1. Initialize a Godot project under `game/`.
2. Add `.gitignore` rules for generated imports, local saves, and secret files.
3. Add data validators under `tools/validators/`.
4. Implement player movement and camera first.
5. Implement five sample NPCs using the schema above.
6. Implement a local save file with versioning and checksum.
7. Implement a simple local admin data viewer before any online backend.
8. Add automated checks for data references and asset license entries.

## 12. Related Implementation Plan

Use `docs/IMPLEMENTATION_PLAN.md` as the Phase 0-12 build order for applying this engineering plan. The implementation plan defines gates, deliverables, exit criteria, cross-phase validation rules, and the first two-week sprint proposal.

Phase-specific files in `docs/phases/` provide the executable checklists for each phase.
