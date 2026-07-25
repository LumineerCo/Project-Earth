# Project Earth Phase Files

These files expand the master implementation plan into phase-specific engineering checklists. Use them with `docs/IMPLEMENTATION_PLAN.md`; the phase file provides detailed work guidance while the master plan remains the roadmap and gate summary. Each phase file now includes detailed engineering coverage, recommended implementation steps, potential issues to troubleshoot, core deliverables, and an exit gate.

| Phase | File | Focus |
| --- | --- | --- |
| 0 | [Phase 0: Foundation](PHASE_00_FOUNDATION.md) | Set up repository, Godot project, policies, validators, secret handling, and asset-license workflow. |
| 1 | [Phase 1: Playable Core](PHASE_01_PLAYABLE_CORE.md) | Create player movement, camera, interaction, clock, debug overlay, and versioned local save/load. |
| 2 | [Phase 2: Living Block](PHASE_02_LIVING_BLOCK.md) | Build a small alive town block with persistent NPCs, homes, workplaces, and schedule-driven behavior. |
| 3 | [Phase 3: Work and Economy](PHASE_03_WORK_AND_ECONOMY.md) | Add legal jobs, inventory, shops, item prices, wages, and anti-duplication save behavior. |
| 4 | [Phase 4: Travel and Zones](PHASE_04_TRAVEL_AND_ZONES.md) | Add streaming/travel between town, village/farm, and wilderness zones with vehicle and weather foundations. |
| 5 | [Phase 5: Business and Property](PHASE_05_BUSINESS_AND_PROPERTY.md) | Implement first player-owned business and basic housing/property state. |
| 6 | [Phase 6: Adventure Layer](PHASE_06_ADVENTURE_LAYER.md) | Add wilderness exploration, repeatable POIs, safe hazards, resource rewards, and adventure log. |
| 7 | [Phase 7: Life Simulation Expansion](PHASE_07_LIFE_SIMULATION_EXPANSION.md) | Deepen player needs, NPC relationships, housing, clothing comfort, and reputation without punishing casual play. |
| 8 | [Phase 8: Civic Systems and Services](PHASE_08_CIVIC_SYSTEMS_AND_SERVICES.md) | Add city services, lawful consequences, public transport, incident reports, and dynamic civic events. |
| 9 | [Phase 9: Admin and QA Hardening](PHASE_09_ADMIN_AND_QA_HARDENING.md) | Build admin observability, audit logs, validators, performance reports, save tests, and asset checks. |
| 10 | [Phase 10: Content Expansion and Mod Readiness](PHASE_10_CONTENT_EXPANSION_AND_MOD_READINESS.md) | Expand content while ensuring new districts, jobs, vehicles, and packs load via validated data. |
| 11 | [Phase 11: Online Optional Operations](PHASE_11_ONLINE_OPTIONAL_OPERATIONS.md) | Keep offline-first gameplay while preparing optional self-hosted backend, backups, moderation, and privacy workflows. |
| 12 | [Phase 12: Release Candidate](PHASE_12_RELEASE_CANDIDATE.md) | Freeze scope, optimize, validate accessibility/licenses, package builds, and remove blockers. |
