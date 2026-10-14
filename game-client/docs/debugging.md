# Debugging Toolchain

> Project Earth — Developer Debugging Guide
> Stage 2.8 — Debug Framework

Project Earth ships with an in-game debug framework accessible at runtime. This document describes each tool, how to invoke it, and how to extend it.

---

## 1. DebugManager (Logging)

The foundation. All logging flows through the `DebugManager` autoload.

### Log Levels

| Level | Value | Use |
|---|---|---|
| TRACE | 0 | Per-frame spam, hot-path diagnostics |
| DEBUG | 1 | Detailed state during development |
| INFO | 2 | Lifecycle events (default release level) |
| WARN | 3 | Recoverable problems |
| ERROR | 4 | Failures that degrade gameplay |
| FATAL | 5 | Unrecoverable; game cannot continue |

### API

```gdscript
DebugManager.log_trace("NPCManager", "Tick: %d npcs" % count)
DebugManager.log_debug("EconomyManager", "Recalculated prices")
DebugManager.log_info("Boot", "World data loaded")
DebugManager.log_warn("SaveManager", "Slot 2 missing meta, recreating")
DebugManager.log_error("WorldServer", "Connection lost: %s" % err)
DebugManager.log_fatal("Boot", "Critical asset missing: %s" % path)
```

- `DebugManager.min_log_level` — set the floor (default INFO).
- `DebugManager.enabled` — master switch.
- `DebugManager.log_to_file` / `log_to_console` — output sinks.
- `DebugManager.get_recent_logs(count)` — ring buffer for the console.
- `DebugManager.log_emitted` — signal fired on every log; the console listens.

### Log File
Runtime logs are written to `user://logs/game.log`. On desktop this resolves to:
- Linux: `~/.local/share/godot/app_userdata/Project-Earth/logs/game.log`
- Windows: `%APPDATA%\Godot\app_userdata\Project-Earth\logs\game.log`
- macOS: `~/Library/Application Support/Godot/app_userdata/Project-Earth/logs/game.log`

---

## 2. DebugConsole (In-Game Console)

A togglable command-line interface layered over the game.

### Toggle
- **Backtick** key (`` ` ``), or
- The `toggle_debug` input action (configurable in `project.godot`).

### Built-in Commands

| Command | Args | Description |
|---|---|---|
| `help` | — | List all registered commands |
| `clear` | — | Clear console output |
| `quit` | — | Quit the game |
| `fps` | — | Show current FPS |
| `time` | `[hh:mm]` | Show or set world time |
| `loglevel` | `<0-5>` | Set `DebugManager.min_log_level` |
| `state` | — | Show current `GameManager` state |
| `seed` | `[value]` | Show or set `GameManager.world_seed` |
| `perf` | — | Toggle Performance Monitor overlay |
| `inspector` | — | Toggle World Inspector overlay |

### Registering Custom Commands

Any system can register a command at runtime:

```gdscript
func _ready() -> void:
    DebugConsole.register("spawn", _cmd_spawn, "Spawn an NPC at player", "<npc_id>")

func _cmd_spawn(args: Array[String]) -> String:
    var id := args[0] if args.size() > 0 else "random"
    # ... spawn logic ...
    return "Spawned %s" % id
```

- Command names are lowercased automatically.
- The callable receives `Array[String]` (tokenized args) and returns a `String` (printed to console).
- A `command_executed(command, success)` signal fires after each call.

---

## 3. PerformanceMonitor (F3)

A real-time overlay showing engine and gameplay metrics.

### Toggle
- **F3** key, or
- `DebugConsole` → `perf` command.

### Metrics Tracked
- **FPS** (color-coded: green ≥55, yellow ≥30, red <30) with trend sparkline
- **Frame time** (ms) with trend
- **Memory** — static + dynamic (render) with trend
- **Object counts** — nodes, physics bodies, physics areas
- **Gameplay counts** — NPCs (via `NPCManager`), vehicles (group), audio streams, animations

### Refresh
- Samples every 0.1s, refreshes display every 0.25s, trend buffer holds 60 samples.

---

## 4. WorldInspector (F4)

A real-time overlay showing the player's current world context.

### Toggle
- **F4** key, or
- `DebugConsole` → `inspector` command.

### Information Shown
- **Location** — continent, country, state, city (nearest from `data/cities/`), district, chunk key
- **Coordinates** — X/Y/Z and elevation
- **Environment** — time of day, day number, weather (when `WeatherManager` is loaded)
- **Entities** — nearby NPC and vehicle counts

### Chunk Key
Chunks are 256m × 256m (per Stage 1.6). The inspector computes the chunk as `Vector2i(floor(x/256), floor(z/256))`.

---

## 5. HUD Debug Panel

The player HUD (`scripts/ui/HUD.gd`) includes a small debug panel (top-left) showing FPS, coordinates, game state, world time, and streaming status. Updated every 0.25s. This is always visible during play; the overlays above are on-demand.

---

## 6. Extending the Framework

To add a new debug overlay:
1. Create `scripts/debug/MyTool.gd` extending `CanvasLayer` with `class_name MyTool`.
2. Build UI in `_ready()`, sample in `_process()`, toggle on a key in `_unhandled_input()`.
3. Register as an autoload in `project.godot` (after `DebugManager`).
4. Add a `DebugConsole` command to toggle it.
5. Log readiness via `DebugManager.log_info("MyTool", "Ready")`.
6. Verify with the editor error checker; document the tool here.
