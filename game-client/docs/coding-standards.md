# Coding Standards

> Project Earth — Programming Conventions
> Godot 4.x · GDScript

This document defines the folder, naming, and style conventions for all GDScript in the project. Following these keeps the codebase consistent across hundreds of files and many contributors.

---

## 1. Folder Conventions

| Folder | Contents |
|---|---|
| `autoload/` | Singletons registered in `project.godot` |
| `scripts/<domain>/` | Domain logic (world, economy, npc, vehicle, …) |
| `scenes/<domain>/` | Scene trees mirroring `scripts/<domain>/` |
| `data/` | Pure JSON content (no code) |
| `shaders/` | `.gdshader` files |
| `configs/` | Runtime config files |
| `tests/` | Prototype test scenes & scripts |
| `tools/` | Dev automation (editor scripts, validators) |

A script and its scene live in mirrored paths:
- `scripts/player/PlayerController.gd` ↔ `scenes/player/Player.tscn`

---

## 2. Naming Conventions

### Files
- `PascalCase.gd` for classes: `PlayerController.gd`, `EconomyManager.gd`
- `snake_case.json` for data: `city_san_francisco.json`, `item_bread.json`
- `snake_case.tscn` for scenes: `player.tscn`, `boot.tscn`

### Identifiers
- `snake_case` for variables and functions: `get_active_count()`, `world_seed`
- `PascalCase` for classes and enums: `class_name PlayerController`, `enum GameState`
- `UPPER_SNAKE_CASE` for constants: `MAX_ACTIVE_NPCS`, `SPAWN_RADIUS`
- `_leading_underscore` for private members: `_active_npcs`, `_spawn_timer`

### Signals
- Past-tense or event-named: `npc_spawned(npc)`, `save_completed(slot)`, `command_executed(cmd, ok)`
- Snake case: `console_toggled`, not `ConsoleToggled`

### Enums
```gdscript
enum LogLevel { TRACE, DEBUG, INFO, WARN, ERROR, FATAL }
enum GameState { BOOTING, MAIN_MENU, LOADING, PLAYING, PAUSED, SAVING, ERROR }
```

---

## 3. File Header

Every `.gd` file begins with a header comment block:

```gdscript
## PlayerController.gd
## Third-person player movement and interaction.
## Stage 2.3 — Game Project Setup
extends CharacterBody3D
class_name PlayerController
```

- Line 1: filename
- Line 2: one-sentence purpose
- Line 3: stage/phase reference
- Then `extends` and `class_name` (if applicable)

---

## 4. Section Layout

Organize a script into clearly delimited sections, in this order:

```gdscript
## ──────────────────────────────────────────────
##  Signals
## ──────────────────────────────────────────────

signal npc_spawned(npc: Node)

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const MAX_ACTIVE_NPCS := 80
const SPAWN_RADIUS := 120.0

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _active_npcs: Dictionary = {}

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void: ...
func _process(delta: float) -> void: ...

## ──────────────────────────────────────────────
##  Public API
## ──────────────────────────────────────────────

func get_active_count() -> int: ...

## ──────────────────────────────────────────────
##  Internal
## ──────────────────────────────────────────────

func _manage_population() -> void: ...
```

---

## 5. Typing

- **Always type** function signatures: `func get_npc(id: String) -> Node:`
- **Always type** variables when the type isn't obvious: `var count: int = 0`
- Use `:=` for inferred constants: `const CHUNK_SIZE := 256`
- Prefer typed arrays: `Array[String]`, `Array[Dictionary]`
- Use `Variant`/untyped only for JSON-parsed data.

---

## 6. Constants Over Magic Numbers

No bare numbers/strings in logic. Define a `const` in the Configuration section:

```gdscript
const SPAWN_INTERVAL := 0.5  # seconds between spawn checks
```

---

## 7. Design Patterns

### Singleton (Autoload)
Global managers are autoloads. They expose a typed API and emit signals; they never reach into other singletons' internals.

### Data-Driven
Content lives in JSON; managers load and validate it. See `docs/architecture.md` § Data-Driven World Design.

### Signal Bus
Cross-system communication uses signals, not direct calls where possible. `MemoryEventBus` is the central pub/sub for NPC memory.

### Composition Over Inheritance
NPCs, vehicles, and items compose small reusable components rather than deep inheritance trees.

---

## 8. Error Handling

- Validate inputs at public API boundaries; return early on invalid input.
- Log all failures via `DebugManager` with a category string.
- Never `push_error()` in hot paths — use `DebugManager.log_error()`.
- Save/load operations are transactional (temp file + rename).

```gdscript
if not data.has("position"):
    DebugManager.log_warn("WorldData", "City '%s' missing position, skipped" % id)
    return
```

---

## 9. Logging

See `docs/debugging.md`. In short:
- Use the appropriate level (TRACE for spammy per-frame, INFO for lifecycle, WARN for recoverable, ERROR for failures).
- Always pass a **category** string (the system name): `"NPCManager"`, `"EconomyManager"`.
- Never log secrets or player PII.

---

## 10. Comments

- `##` doc comments above public declarations (shown in editor tooltips).
- `#` inline comments only for *why*, not *what*.
- Keep examples in docs short and focused.
