# Tests

> Project Earth — System Tests
> Stage 2.12 — First Prototype

This folder contains basic integration tests that verify core systems work correctly together. These are not full unit tests yet (Stage 3+), but essential validation during prototype development.

---

## Test Suite

### `test_core_systems.gd`

Validates that all core autoload singletons initialize correctly and have expected APIs.

**Tests:**
- GameManager initialization (state, version, seed)
- DebugManager logging (enabled, buffering)
- WorldTime basics (hour/minute getters, format)
- SaveManager paths (user:// structure, list_saves)
- EconomyManager initialization
- NPCManager initialization (get_active_count)

**Run:**
```gdscript
var t = load("res://tests/test_core_systems.gd").new()
t.run_all()
```

### `test_save_system.gd`

Tests save and load infrastructure.

**Tests:**
- SaveManager exists and is registered
- Save paths use `user://` directories
- `list_saves()` returns an array

**Run:**
```gdscript
var t = load("res://tests/test_save_system.gd").new()
t.run_all()
```

### `test_world_time.gd`

Tests in-game time system.

**Tests:**
- WorldTime exists and is registered
- `get_hour()` / `get_minute()` / `get_second()` return valid ranges
- `get_time_string()` is formatted correctly
- `set_time_scale()` works
- `get_day_progress()` returns 0-1

**Run:**
```gdscript
var t = load("res://tests/test_world_time.gd").new()
t.run_all()
```

---

## Running Tests

From the Godot editor console (Debug tab in the Script editor):

```gdscript
# Run one test suite
var t = load("res://tests/test_core_systems.gd").new()
t.run_all()

# Output will print to console with pass/fail summary
```

---

## Test Framework (Minimal)

All tests extend `Node` and follow this pattern:

```gdscript
extends Node
class_name MyTest

var _results := { "passed": 0, "failed": 0, "tests": [] }

func run_all() -> void:
    # Run individual tests
    test_something()
    test_another()
    print_results()

func test_something() -> void:
    if condition:
        _pass("test name")
    else:
        _fail("test name", "reason")

func _pass(name: String) -> void:
    _results["passed"] += 1
    print("✓ %s" % name)

func _fail(name: String, reason: String) -> void:
    _results["failed"] += 1
    print("✗ %s: %s" % [name, reason])

func print_results() -> void:
    # Print summary
    pass
```

---

## Future Test Suites (Stage 3+)

- **test_economy.gd** — Price calculations, transactions
- **test_npc_memory.gd** — NPC memory events and storage
- **test_player_controller.gd** — Movement, interaction
- **test_ui_integration.gd** — UI ↔ game communication
- **test_world_streaming.gd** — Chunk loading/unloading
- **test_save_corruption.gd** — Save integrity under crash conditions
