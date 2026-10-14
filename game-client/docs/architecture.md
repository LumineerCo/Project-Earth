# Technical Architecture

> Project Earth — Technical Architecture Reference
> Stage 2 (Prototype) · Godot 4.x · GDScript

This document describes how the game is structured internally: engine configuration, rendering/physics settings, autoload singletons, the boot sequence, and the data-driven world design pattern.

---

## 1. Engine & Renderer

| Setting | Value |
|---|---|
| Engine | Godot 4.x (Forward+ renderer) |
| Main scene | `res://scenes/boot/Boot.tscn` |
| Resolution | 1920×1080 |
| Gravity | 9.8 m/s² |
| Scale | 1 Godot Unit = 1 Meter |

The Forward+ renderer is chosen for its modern feature set (clustered lighting, volumetrics, post-processing) which scales well to large open-world scenes.

---

## 2. Autoload Singletons

Autoloads are registered in `project.godot` under `[autoload]`. They initialize in order, top to bottom.

| Order | Singleton | Path | Role |
|---|---|---|---|
| 1 | `GameManager` | `autoload/GameManager.gd` | Game state machine, world seed, player data |
| 2 | `WorldTime` | `autoload/WorldTime.gd` | In-game clock (scaled real-time) |
| 3 | `MemoryEventBus` | `autoload/MemoryEventBus.gd` | NPC memory event pub/sub |
| 4 | `MemoryStore` | `autoload/MemoryStore.gd` | NPC memory persistence |
| 5 | `EconomyManager` | `autoload/EconomyManager.gd` | Prices, transactions, market state |
| 6 | `WorldServerBridge` | `autoload/WorldServerBridge.gd` | Shared-world networking stub |
| 7 | `SaveManager` | `scripts/save/SaveManager.gd` | Save/load to `user://saves/` |
| 8 | `DebugManager` | `autoload/DebugManager.gd` | Structured logging (TRACE→FATAL) |
| 9 | `DebugConsole` | `scripts/debug/DebugConsole.gd` | In-game command console (backtick) |
| 10 | `PerformanceMonitor` | `scripts/debug/PerformanceMonitor.gd` | FPS/memory/object overlay (F3) |
| 11 | `WorldInspector` | `scripts/debug/WorldInspector.gd` | World context overlay (F4) |
| 12 | `NPCManager` | `autoload/NPCManager.gd` | NPC population around player |

> **Order matters.** `DebugManager` must load before any singleton that logs during `_ready()`.

---

## 3. Boot Sequence

`scenes/boot/Boot.tscn` → `scripts/core/Boot.gd` runs an ordered sequence of boot steps. Each step is a method that returns `bool` (success). The boot screen reports progress; on failure, the game enters `GameManager.GameState.ERROR`.

Boot steps (Stage 2):
1. Initialize debug logging
2. Load configuration
3. Seed RNG (`GameManager.world_seed`)
4. Initialize economy
5. Initialize memory systems
6. Initialize world server bridge
7. Load world data (JSON)
8. Initialize NPC manager
9. Validate player data
10. Transition to `MAIN_MENU`

After the player starts a new game, `Game.gd` (`scenes/main/Game.tscn`) takes over: sets state to `PLAYING`, spawns the player, sets up the world, HUD, and day/night cycle.

---

## 4. Data-Driven World Design Pattern

Project Earth uses a strict **data-driven** pattern for all world content. This keeps gameplay logic decoupled from content and makes the world moddable.

```
┌─────────────────┐      ┌──────────────────┐      ┌─────────────────┐
│  JSON Data      │ ───▶ │  Manager (GDScript)│ ───▶ │  Boot.gd Step   │
│  data/world/    │      │  scripts/world/    │      │  scripts/core/  │
└─────────────────┘      └──────────────────┘      └─────────────────┘
```

- **Data**: Pure JSON in `game-client/data/` (cities, countries, items, jobs, npc, regions, roads, shops, vehicles, weather, world). No logic.
- **Manager**: A GDScript class that loads, validates, caches, and exposes the data via a typed API. Lives in `scripts/world/` (or `scripts/economy/`, etc.).
- **Boot step**: A method in `Boot.gd` that instantiates/initializes the manager and wires it into the game.

**Rules:**
1. Managers never hardcode content — always read from JSON.
2. JSON schemas are validated at load time; invalid entries are logged via `DebugManager` and skipped.
3. Every manager exposes a `get_*()` query API, not raw dictionaries, to callers.

---

## 5. Project Structure

```
game-client/
├── project.godot          # Engine config + autoload registry
├── autoload/              # Global singletons (registered in project.godot)
├── scripts/
│   ├── core/              # Boot.gd, Game.gd — lifecycle
│   ├── player/            # PlayerController.gd
│   ├── world/             # World data managers
│   ├── economy/           # Economy systems
│   ├── npc/               # NPC AI & behavior
│   ├── vehicle/           # Vehicle physics
│   ├── weather/           # Weather systems
│   ├── save/              # SaveManager
│   ├── debug/             # DebugConsole, PerformanceMonitor, WorldInspector
│   ├── ui/                # HUD, menus
│   ├── audio/             # Audio managers
│   ├── network/           # WorldServerBridge helpers
│   └── editor/           # Editor tooling
├── scenes/                # .tscn scene trees (mirror scripts/ layout)
├── data/                  # JSON world content (data-driven)
├── assets/                # Binary art/audio assets
├── shaders/               # .gdshader files
├── configs/               # Runtime config (JSON/ini)
├── localization/          # Translation CSVs
├── docs/                  # This documentation
├── tools/                 # Dev automation scripts
├── tests/                 # Prototype test scenes/scripts
├── mods/                  # Mod loadout folder
└── exports/               # Build output (gitignored)
```

---

## 6. Streaming Architecture (Stage 1.6)

The world is divided into 256m × 256m chunks. Only chunks within the player's streaming radius are loaded; distant chunks are unloaded. See `docs/architecture.md` § Streaming for the full design (Stage 3 implements the runtime).

---

## 7. Save System

`SaveManager` writes JSON snapshots to `user://saves/`. Each slot is a directory containing `meta.json` and `world.json`. The system is transactional: a save is written to a temp file first, then atomically renamed, to prevent corruption on crash.

---

## 8. Logging Standards

All logging goes through `DebugManager`:

```gdscript
DebugManager.log_info("NPCManager", "Spawned npc_42 at (120, 0, -45)")
DebugManager.log_warn("EconomyManager", "Price for 'bread' below floor: clamped")
DebugManager.log_error("SaveManager", "Failed to write slot 3: ", err)
```

- **Levels**: TRACE(0) DEBUG(1) INFO(2) WARN(3) ERROR(4) FATAL(5)
- `min_log_level` filters output; default INFO in release, DEBUG in dev.
- Logs go to console (editor) and `user://logs/game.log` (runtime).
- A ring buffer keeps the last N logs for the in-game console.

See `docs/debugging.md` for the full debugging toolchain.
