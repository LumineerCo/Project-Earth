# Project Earth Phased Implementation Plan

## 1. Purpose

This plan turns the GDD and engineering plan into a practical build order. It assumes a Rs.00 direct-spend constraint, free/open-source tooling, offline-first gameplay, and scalable performance for Android mobile, low-end laptops, and desktop PCs.

## 2. Current Documentation Review

The current documentation is a strong vision foundation, but implementation can fail if the team tries to build the full open world immediately. The safest path is to prove the core living-world loop in a tiny vertical slice, then expand only after performance, save stability, data validation, and admin observability are working.

Key issues to control from the start:

- **Scope risk:** A realistic Earth-inspired life simulator is too large for a first milestone unless the world is deliberately constrained.
- **Simulation risk:** Full-detail NPCs, traffic, businesses, and weather cannot run everywhere at once on mobile hardware.
- **Security risk:** Admin credentials must be bootstrapped securely and must never be committed or shipped in the client.
- **Licensing risk:** Free assets still require license review, attribution, and compatibility tracking.
- **Save risk:** Broken save migrations can destroy player progress if versioning is added late.
- **Tooling risk:** Without validators, data-driven NPCs, shops, jobs, and items will accumulate broken references.

## 3. Phase Gates

Each phase has a gate. Do not begin the next phase until the gate passes.

| Phase | Name | Main goal | Gate |
| --- | --- | --- | --- |
| 0 | Foundation | Repo, tooling, policies, Godot setup | Project opens and exports a blank Android/desktop build |
| 1 | Playable Core | Player movement, camera, time, save/load | Player can move, interact, save, quit, reload |
| 2 | Living Block | Small town block with NPC schedules | 10 NPCs follow visible schedules for 2 in-game days |
| 3 | Work and Economy | Jobs, shops, money, inventory | Player earns/spends money and prices persist in saves |
| 4 | Travel and Zones | Town, village, wilderness streaming | Player travels between 3 zones without save corruption |
| 5 | Business and Property | Player business loop | Player stocks, prices, and earns from one business |
| 6 | Adventure Layer | Exploration events and hazards | Wilderness offers repeatable adventure without breaking economy |
| 7 | Life Simulation Expansion | Needs, relationships, housing, reputation | Player lifestyle choices change NPC reactions and daily costs |
| 8 | Civic Systems and Services | Law, emergency services, public transport, city events | City services respond to incidents and scheduled events |
| 9 | Admin and QA Hardening | Monitoring, audit logs, validation, performance | Admin can inspect data and tests protect core systems |
| 10 | Content Expansion and Mod Readiness | More districts, biomes, jobs, vehicles, asset pipeline | New content can be added through validated data without code changes |
| 11 | Online-Optional Operations | Self-hosted backend option, backups, moderation workflows | Offline works fully and optional self-hosted services pass security checks |
| 12 | Release Candidate | Optimization, accessibility, packaging | Mobile low profile and desktop profile pass acceptance checks |

## 4. Phase 0: Foundation

### Objectives

- Create the real project structure.
- Initialize Godot under `game/`.
- Add `.gitignore` for generated files, local saves, exports, and secret files.
- Create base data folders for NPCs, schedules, items, businesses, districts, jobs, vehicles, and events.
- Add placeholder validators under `tools/validators/`.
- Add local development documentation for admin bootstrap.

### Deliverables

- `game/project.godot` opens in the selected Godot version.
- `game/data/` contains example JSON files for one district, one NPC, one schedule, one item, one job, and one shop.
- `tools/validators/validate_data.py` or equivalent script checks IDs and required fields.
- `ASSET_LICENSES.md` remains the source of truth for asset usage.

### Exit Criteria

- Blank desktop build can be launched.
- Blank Android export preset exists or is documented.
- Data validator runs successfully on example data.
- No plaintext admin password exists in tracked files.

## 5. Phase 1: Playable Core

### Objectives

- Implement player controller for keyboard/mouse and mobile touch abstraction.
- Add third-person or top-down camera suitable for low-end devices.
- Implement interaction prompts.
- Implement in-game clock.
- Implement local save/load with version and checksum.
- Add developer debug overlay for FPS, loaded zone, active NPC count, and quality level.

### Deliverables

- Player can walk around a greybox scene.
- Player can interact with a test object.
- Save file stores player position, time, inventory, money, and settings.
- Save migration function exists even if only one version is supported.

### Exit Criteria

- Save, quit, reload returns the player to the same state.
- Corrupt save file is detected and does not crash the game.
- Debug overlay can be toggled off for normal play.

## 6. Phase 2: Living Block

### Objectives

- Implement one small town block with homes, roads, a shop, and a workplace.
- Implement NPC spawning from data.
- Implement schedule evaluation.
- Implement simple path targets without expensive global pathfinding.
- Implement abstract updates for off-screen NPCs.

### Deliverables

- 10 persistent NPCs.
- At least 3 schedule archetypes: shop worker, commuter, unemployed/local resident.
- NPCs travel between home, work, market, and rest points.
- NPC state persists in save data.

### Exit Criteria

- 10 NPCs complete 2 in-game days without getting permanently stuck.
- Low-end profile stays within the target frame budget in the test block.
- Admin/debug view can list NPC current action and next schedule action.

## 7. Phase 3: Work and Economy

### Objectives

- Add player wallet and inventory.
- Add shop buy/sell transactions.
- Add simple jobs: delivery, farm helper, shop assistant, courier, taxi/bus helper.
- Add district-based price multipliers.
- Add wages, job completion, and reputation changes.

### Deliverables

- Five jobs available through the in-game phone or job board.
- One grocery shop and one service provider.
- Basic item catalog with food, fuel/charge token, repair part, and quest item categories.
- Economy values persist in saves.

### Exit Criteria

- Player can earn money legally and spend it.
- Job rewards cannot be duplicated through save/load abuse in normal play.
- Shop inventory decreases/increases correctly.

## 8. Phase 4: Travel and Zones

### Objectives

- Add zone streaming for town, village/farm, and wilderness.
- Add travel triggers: bus stop, road gate, foot path, or loading transition.
- Add simple vehicle ownership for bicycle or motorbike.
- Add weather changes that affect travel ambience and future systems.

### Deliverables

- Three MVP zones.
- Travel UI through in-game phone or bus stop.
- One basic owned vehicle.
- Weather state saved and restored.

### Exit Criteria

- Player can travel between all zones repeatedly without duplicate entities.
- Save/load works in every zone.
- Low-end profile unloads inactive zones correctly.

## 9. Phase 5: Business and Property

### Objectives

- Implement one player-owned business type first, preferably a food stall or grocery stall.
- Add stock purchase, pricing, customer visits, simple employee slot, and daily profit/loss summary.
- Add simple rented room/property ownership flag.

### Deliverables

- Player can rent or acquire a small business spot.
- Player can stock inventory and set price multiplier.
- NPC customers buy items based on needs and price tolerance.
- Daily business summary appears on phone.

### Exit Criteria

- Business can make profit or loss depending on stock and pricing.
- Business state persists after travel and save/load.
- Economy admin view can inspect business inventory and revenue.

## 10. Phase 6: Adventure Layer

### Objectives

- Add wilderness exploration loop.
- Add repeatable points of interest.
- Add non-graphic hazards such as weather, stamina/energy loss, blocked paths, wildlife avoidance, or getting lost.
- Add rewards that do not inflate the economy too quickly.

### Deliverables

- Cave or ruin greybox.
- 5 exploration events.
- 3 collectible/resource types.
- Adventure log on phone.

### Exit Criteria

- Player can complete exploration and return safely.
- Rewards are capped or balanced against job/business income.
- Adventure events save and do not repeat incorrectly unless designed as repeatable.

## 11. Phase 7: Life Simulation Expansion

### Objectives

- Add deeper optional player needs such as hunger, thirst, energy, hygiene, mood, and comfort.
- Add relationship levels, trust, rivalry, friendship, employer reputation, and local community reputation.
- Add housing upgrades, rent/bills, storage, sleeping, and decoration hooks.
- Add clothing and weather comfort effects without making casual mode too punishing.

### Deliverables

- Needs model with casual/normal/realism presets.
- Relationship memory for repeated player-NPC interactions.
- Basic rented room upgrades and storage.
- Reputation changes visible through the phone UI.

### Exit Criteria

- Player can complete a full in-game week with needs enabled and no unavoidable failure loop.
- NPC reactions change based on relationship and reputation data.
- Needs and relationships persist after save/load and travel.

## 12. Phase 8: Civic Systems and Services

### Objectives

- Add city services that make urban areas feel alive: police patrols, clinics, fire/emergency response, sanitation, and public transport schedules.
- Add lawful consequences for traffic violations, theft, trespassing, and business fraud in a non-glorifying way.
- Add public events such as festivals, strikes, road closures, elections, storms, and market days.
- Add service disruptions that affect travel, prices, and NPC schedules.

### Deliverables

- Police, clinic/medical, transport, and city maintenance service archetypes.
- Incident report data model.
- Public transport timetable data.
- 10 civic/dynamic city events.

### Exit Criteria

- At least three service types visibly respond to incidents or schedules.
- Player legal status affects fines, NPC trust, and admin inspection data.
- Public transport and city events update NPC schedules without breaking jobs.

## 13. Phase 9: Admin and QA Hardening

### Objectives

- Build a local/self-hosted admin dashboard or development admin view.
- Add role definitions and audit log model.
- Add data validators to CI or local scripts.
- Add headless simulation tests where possible.
- Add save migration tests.
- Add asset license validation.
- Add performance capture for low, medium, and high quality presets.

### Deliverables

- Admin can inspect player profile, NPCs, businesses, economy, active events, service incidents, and audit logs.
- Admin mutation actions write audit records.
- Validator checks missing IDs, duplicate IDs, invalid schedules, invalid prices, and missing asset license records.
- Basic test commands documented.
- Performance report template for mobile and desktop profiles.

### Exit Criteria

- Unauthorized admin route/action is blocked in development test mode.
- Every admin mutation writes an audit log.
- Data validators pass on all committed data files.
- No tracked file contains real secrets.
- Performance reports identify the top three bottlenecks per profile.

## 14. Phase 10: Content Expansion and Mod Readiness

### Objectives

- Expand from MVP content to additional districts, village variants, wilderness points of interest, jobs, vehicles, and NPC archetypes.
- Make content packs data-driven so future districts can be created without engine-code changes.
- Add import rules for models, textures, audio, and map-inspired data.
- Prepare a safe modding boundary for local community content after the base game is stable.

### Deliverables

- At least 3 town districts, 2 village/farm variants, and 2 wilderness POI sets.
- 10+ job templates and 5+ player business templates.
- 20+ vehicle/item templates combined.
- Content pack manifest format.
- Asset import checklist tied to `ASSET_LICENSES.md`.

### Exit Criteria

- New content pack can be validated and loaded without changing core code.
- Missing or invalid content pack references fail validation with useful errors.
- Performance remains within MVP budget after added content density is enabled.

## 15. Phase 11: Online-Optional Operations

### Objectives

- Keep the game fully offline playable while preparing optional self-hosted services for cloud saves, admin monitoring, backups, and moderation.
- Define backup/restore flows for player saves and admin data.
- Add privacy-aware data export/delete design.
- Add anti-abuse checks only for online/self-hosted modes.

### Deliverables

- Offline-only mode remains default and complete.
- Optional self-hosted service architecture document or prototype.
- Backup and restore checklist.
- Moderation workflow for reports, bans, warnings, and appeal notes.
- Privacy export/delete workflow.

### Exit Criteria

- Disabling network access does not block core gameplay.
- Optional service stores no plaintext secrets and uses role-based admin access.
- Backup restore succeeds on test data.
- Admin/moderation actions remain audited.

## 16. Phase 12: Release Candidate

### Objectives

- Optimize scenes, textures, LODs, NPC density, traffic density, and shader complexity.
- Add accessibility settings.
- Finalize MVP tutorial.
- Validate licenses.
- Package Android and desktop builds.
- Stabilize crash/error reporting for local logs.
- Freeze content scope and focus on bug fixing.

### Deliverables

- Android build.
- Desktop build.
- Settings menu with quality presets.
- Credits/license screen.
- MVP tutorial path.
- Known issues document.
- Release checklist.

### Exit Criteria

- Low-end mobile profile targets 30 FPS in MVP zones.
- Desktop profile targets 60 FPS in MVP zones.
- Save/load passes after 20 repeated cycles.
- Asset license registry is complete for all included non-original assets.
- No critical security, save-corruption, or blocker gameplay bugs remain.

## 17. Cross-Phase Technical Decisions

### 17.1 Data Validation Rules

Validators should fail on:

- Duplicate IDs.
- Missing referenced IDs.
- Invalid time strings.
- Negative prices or wages unless explicitly allowed.
- NPC schedule without a valid home fallback.
- Business inventory referencing unknown items.
- Asset paths without license registry entries.
- Admin role definitions with no owner role.

### 17.2 Save Migration Rules

- Never overwrite a save until the new save validates.
- Every save includes `schema_version`.
- Every schema change includes a migration function.
- Migrations should be idempotent where practical.
- Keep at least one backup save.

### 17.3 Performance Rules

- Prefer pooled NPCs and vehicles.
- Reduce density before reducing core gameplay.
- Use abstract simulation for off-screen entities.
- Avoid expensive per-frame searches across all entities.
- Avoid unbounded physics bodies and dynamic lights on mobile.
- Track frame time, not only FPS.

### 17.4 Security Rules

- Use environment variables or local setup for bootstrap credentials.
- Hash passwords with a modern password-hashing algorithm before storage.
- Keep secrets out of Git, game exports, screenshots, logs, and crash reports.
- Require audit logs for admin mutations.
- Treat the shipped game client as untrusted.

## 18. First Two-Week Sprint Proposal

### Sprint Goal

Create a greybox Godot project with player movement, data examples, validation, and a secure admin bootstrap plan.

### Tasks

1. Initialize Godot project under `game/`.
2. Add `.gitignore` for Godot imports, exports, local saves, `.env`, and secret files.
3. Create data folders and sample JSON files.
4. Add a Python data validator for duplicate IDs and required fields.
5. Add player controller prototype.
6. Add debug overlay stub.
7. Document local admin bootstrap steps without committing credentials.
8. Run validator and launch the greybox scene.

### Sprint Demo

- Open the Godot project.
- Move the player in a greybox scene.
- Run the validator successfully.
- Show sample NPC data and schedule data.
- Confirm no plaintext secret is tracked.

## 19. Phase Detail Files

Detailed phase-specific engineering checklists live in `docs/phases/`. Use these files when executing a phase:

- `docs/phases/README.md` is the index.
- `docs/phases/PHASE_00_FOUNDATION.md` through `docs/phases/PHASE_12_RELEASE_CANDIDATE.md` contain enhanced features, deliverables, exit gates, troubleshooting checks, and engineering notes.
