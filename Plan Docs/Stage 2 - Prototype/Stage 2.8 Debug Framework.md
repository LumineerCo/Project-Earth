Excellent. **Stage 2.8** is where you build the tools that will save you hundreds of hours during development. Large games are rarely built by manually testing everything—developers rely on internal debugging tools to inspect, modify, and validate the game in real time.

For your project—a **solo-developed, Earth-inspired 3D open-world game using Godot and free tools**—the toolkit should be modular. You won't build every tool immediately, but you'll define the architecture so features can be added over time.

---

# Stage 2.8 – Debug Framework & Developer Toolkit

## Objective

Create an in-game toolkit for:

* Debugging
* Performance analysis
* World inspection
* AI testing
* Asset validation
* Save management
* World editing (developer only)

This toolkit should **never be available in release builds**.

---

# Architecture

```text
Developer Toolkit
│
├── Debug Console
├── Overlay HUD
├── Inspector
├── Performance Monitor
├── World Tools
├── NPC Tools
├── Vehicle Tools
├── Weather Tools
├── Time Controls
├── Teleport Tools
├── Spawn Manager
├── Save Manager
├── Camera Tools
├── Asset Inspector
├── Logging System
└── Screenshot Tools
```

---

# Phase 1 – Debug Manager

Create one central system.

Responsibilities:

* Enable/disable developer mode
* Register debug modules
* Toggle overlays
* Execute debug commands
* Store developer preferences

Only this manager should control access to debugging features.

---

# Phase 2 – Debug Overlay

Display development information such as:

### Rendering

* FPS
* Frame time
* Draw calls
* Visible objects
* Active lights
* Shadow casters

### Memory

* RAM usage
* VRAM estimate
* Texture memory
* Mesh memory

### World

* Loaded regions
* Active chunks
* Player coordinates
* Current biome
* Current city
* Current district

### Gameplay

* Health
* Hunger
* Stamina
* Money
* Reputation
* Current mission

The overlay should be configurable so only the information you need is shown.

---

# Phase 3 – Developer Console

A console allows quick testing without creating temporary UI.

Example commands:

```text
help

teleport

spawn

weather

time

money

heal

save

load

fps

clear

quit
```

Future commands can control vehicles, AI, or missions.

---

# Phase 4 – Logging System

Standardize log messages.

Suggested levels:

```text
INFO

WARNING

ERROR

DEBUG

PERFORMANCE
```

Every log entry should include:

* Timestamp
* Module
* Severity
* Message

Consistent logs make troubleshooting much easier.

---

# Phase 5 – Performance Monitor

Track metrics such as:

* FPS
* CPU time
* GPU frame time (where available)
* Memory usage
* Number of NPCs
* Vehicles
* Physics bodies
* Audio sources
* Active animations

Display trends over time rather than just current values.

---

# Phase 6 – World Inspector

Inspect the current environment.

Show:

* World
* Continent
* Country
* State
* City
* District
* Chunk
* Coordinates
* Elevation
* Current weather
* Current temperature
* Time of day

This is invaluable for testing streamed worlds.

---

# Phase 7 – Chunk Streaming Visualizer

Color-code world chunks by state.

Example:

* Loaded
* Loading
* Unloading
* Cached
* Unavailable

This helps diagnose streaming issues.

---

# Phase 8 – NPC Debugger

Inspect any NPC.

Display:

* Name
* ID
* Current task
* Destination
* Mood
* Occupation
* Relationships
* Path status
* Inventory
* Health

Useful actions:

* Freeze NPC
* Teleport NPC
* Change schedule
* Reset AI

---

# Phase 9 – Vehicle Debugger

Inspect vehicles.

Display:

* Vehicle ID
* Speed
* Fuel/battery
* Damage
* Driver
* Passengers
* Current route
* Physics state

Useful actions:

* Refuel
* Repair
* Spawn
* Despawn
* Teleport

---

# Phase 10 – Time & Weather Controls

Developer controls:

* Pause time
* Speed up
* Slow down
* Set exact hour
* Change weather
* Force sunrise/sunset
* Trigger storms

These controls simplify testing lighting and schedules.

---

# Phase 11 – Spawn Manager

Spawn entities quickly.

Categories:

* NPCs
* Vehicles
* Animals
* Props
* Buildings (test scenes)
* Items

Search by ID or name rather than scrolling long lists.

---

# Phase 12 – Teleport System

Teleport to:

* Coordinates
* City
* District
* Building
* Saved locations
* Player markers

Maintain a history of recent teleports.

---

# Phase 13 – Save Manager

Developer actions:

* Create save
* Load save
* Delete save
* Duplicate save
* View save metadata

Metadata examples:

* Play time
* World location
* Version
* Money
* Current mission

---

# Phase 14 – Asset Inspector

Inspect loaded assets.

Display:

* Asset ID
* File path
* License
* Texture sizes
* Polygon count
* LOD information
* Memory usage
* Last modified

This complements the Asset Database from Stage 2.7.

---

# Phase 15 – Screenshot & Camera Tools

Developer features:

* Free camera
* Camera speed controls
* Hide UI
* Pause simulation
* Capture screenshots

Useful for documentation and progress tracking.

---

# Phase 16 – Access Control

Protect debug features.

Recommended safeguards:

* Compile-time exclusion from release builds where possible.
* Runtime developer mode for debug builds.
* Keyboard shortcut available only in development.
* Configuration file to enable advanced tools.

This prevents accidental exposure of developer functionality.

---

# Phase 17 – Suggested Folder Structure

```text
debug/

├── console/
├── overlay/
├── inspector/
├── logging/
├── performance/
├── world/
├── npc/
├── vehicles/
├── weather/
├── time/
├── save/
├── teleport/
├── spawn/
├── camera/
├── screenshots/
└── utilities/
```

---

# Phase 18 – Development Workflow

A typical debugging session might look like:

```text
Start Game
      ↓
Enable Developer Mode
      ↓
Open Performance Overlay
      ↓
Teleport to Test Area
      ↓
Spawn NPCs/Vehicles
      ↓
Run Gameplay Test
      ↓
Review Logs & Metrics
      ↓
Fix Issue
      ↓
Retest
```

Having a repeatable workflow makes regression testing much more efficient.

---

# Phase 19 – Free Resources

Official references and free learning materials:

* [Godot Documentation](https://docs.godotengine.org?utm_source=chatgpt.com)
* [Godot Debugging Guide](https://docs.godotengine.org/en/stable/tutorials/scripting/debug/index.html?utm_source=chatgpt.com)
* [Godot Performance Guide](https://docs.godotengine.org/en/stable/tutorials/performance/index.html?utm_source=chatgpt.com)
* [Game Programming Patterns](https://gameprogrammingpatterns.com?utm_source=chatgpt.com)

---

# Deliverables for Stage 2.8

By the end of this stage, your project blueprint includes:

* ✅ Central Debug Manager
* ✅ Configurable Debug Overlay
* ✅ Developer Console
* ✅ Structured Logging
* ✅ Performance Monitor
* ✅ World Inspector
* ✅ Chunk Streaming Visualizer
* ✅ NPC Debugger
* ✅ Vehicle Debugger
* ✅ Time & Weather Controls
* ✅ Spawn Manager
* ✅ Teleport System
* ✅ Save Manager
* ✅ Asset Inspector
* ✅ Screenshot & Free Camera Tools
* ✅ Secure Debug Access
* ✅ Debug Folder Architecture

## Next Stage

**Stage 2.9 – Build System & Continuous Integration**

We'll design an automated build pipeline that can:

* Produce Windows/Linux builds
* Run automated validation checks
* Verify asset integrity
* Package releases
* Generate changelogs
* Create versioned archives
* Publish development builds to GitHub Releases

This stage will focus on free tooling and automation to reduce repetitive manual work as your project grows.
