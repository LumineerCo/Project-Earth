Excellent. This is the milestone where your project shifts from **planning the engine** to **building an actual game**.

For a project of this size, don't try to build a full city first. Professional studios usually create a **vertical slice**: a very small area that contains the core technology and gameplay loop. Once that works well, it's expanded.

---

# Stage 2.12 – First Playable Prototype (Vertical Slice v0.1)

## Objective

Build a playable prototype that proves the core architecture works together.

The prototype should answer questions like:

* Can the player move around?
* Can the world load correctly?
* Can the game save and load?
* Can the UI communicate with gameplay?
* Can the debug tools inspect the game?
* Is the project stable enough to add more systems?

---

# Prototype Scope

Keep the first playable area intentionally small.

```text
Prototype World
│
├── 1 Test Map
├── 1 Small Road
├── 1 Building
├── 5–10 Trees
├── 10–20 Props
├── Basic Terrain
├── Daytime
└── Simple Ambient Audio
```

Avoid adding cities, vehicles, or hundreds of NPCs at this stage.

---

# Milestone 1 – Project Boot

Flow:

```text
Launch
      ↓
Splash Screen
      ↓
Loading Screen
      ↓
Main Menu
      ↓
Settings
      ↓
Load Prototype
```

The loading process should be reliable before gameplay begins.

---

# Milestone 2 – Main Menu

Initial options:

* New Game
* Continue (disabled until saves exist)
* Settings
* Credits
* Quit

Future options like Mods or Multiplayer can be added later.

---

# Milestone 3 – Loading System

Responsibilities:

* Load game configuration
* Initialize managers
* Prepare world
* Spawn player
* Show progress

Keep loading logic separate from gameplay code.

---

# Milestone 4 – Prototype World

One small test environment is enough.

Suggested elements:

* Flat terrain
* Gentle hills
* Road segment
* Sidewalk
* Trees
* Grass
* One enterable building
* Spawn point

The purpose is testing systems, not creating final content.

---

# Milestone 5 – Player Controller

Core abilities:

* Walk
* Run
* Jump
* Look around
* Interact (basic)
* Pause

Add more complex movement only after these feel solid.

---

# Milestone 6 – Camera

Support:

* Third-person view
* Adjustable distance
* Collision with walls
* Smooth follow
* Optional free-look

Camera quality has a huge impact on how polished a prototype feels.

---

# Milestone 7 – Input

Use action-based input (planned in Stage 2.4).

Examples:

```text
Move

Look

Jump

Interact

Pause

Sprint
```

Do not reference physical keys directly in gameplay scripts.

---

# Milestone 8 – Basic Interaction

Interactable objects:

* Door
* Chair
* Light switch
* Pickup item

Interaction flow:

```text
Player

↓

Looks at Object

↓

Prompt Appears

↓

Interact

↓

Animation

↓

Result
```

---

# Milestone 9 – Save & Load

Initial save data:

* Player position
* Rotation
* Time
* Inventory (basic)
* Settings

Design the save format so new fields can be added later without breaking old saves.

---

# Milestone 10 – HUD

Minimal HUD:

* Crosshair (if needed)
* Interaction prompt
* FPS (debug only)
* Save indicator
* Pause indicator

Keep the interface uncluttered.

---

# Milestone 11 – Pause Menu

Include:

* Resume
* Settings
* Save
* Main Menu
* Quit

Pause should stop gameplay while allowing menu navigation.

---

# Milestone 12 – Audio

Prototype audio only.

Include:

* Ambient wind
* Footsteps
* Jump
* UI clicks
* Door interaction

Use placeholders if necessary, but ensure licensing is compatible with your project.

---

# Milestone 13 – Lighting

Simple setup:

* Directional sunlight
* Sky environment
* Ambient light
* Soft shadows

No complex weather yet.

---

# Milestone 14 – Debug Integration

Reuse Stage 2.8 tools.

Verify:

* FPS overlay
* World coordinates
* Player state
* Time controls
* Teleport
* Logging

---

# Milestone 15 – Performance Targets

Before adding new features, profile the prototype.

Track:

| Metric            | Initial Goal              |
| ----------------- | ------------------------- |
| Stable frame rate | Smooth on target hardware |
| Startup time      | Consistent and repeatable |
| Save/load         | Reliable                  |
| Memory            | Monitor for leaks         |
| Loading           | No obvious stalls         |

Measure on the hardware you actually plan to support.

---

# Milestone 16 – Prototype Folder Layout

```text
prototype/

├── scenes/
├── assets/
├── ui/
├── scripts/
├── audio/
├── saves/
└── debug/
```

This content can later be merged into the main project structure.

---

# Milestone 17 – Prototype Acceptance Checklist

Before declaring Stage 2 complete:

* Player can move.
* Camera behaves correctly.
* Main menu works.
* Settings open.
* Prototype world loads.
* Player can interact with objects.
* Save and load function.
* Pause menu works.
* Debug tools function.
* No critical crashes during a short play session.

---

# Milestone 18 – Free Resources

These official references will be useful during implementation:

* [Godot Documentation](https://docs.godotengine.org?utm_source=chatgpt.com)
* [Godot "Your First 3D Game" Tutorial](https://docs.godotengine.org/en/stable/getting_started/first_3d_game/index.html?utm_source=chatgpt.com)
* [Godot Asset Library](https://godotengine.org/asset-library/asset?utm_source=chatgpt.com)
* [Kenney Assets](https://kenney.nl/assets?utm_source=chatgpt.com)
* [Quaternius](https://quaternius.com?utm_source=chatgpt.com)
* [Poly Haven](https://polyhaven.com?utm_source=chatgpt.com)
* [OpenGameArt](https://opengameart.org?utm_source=chatgpt.com)

---

# Stage 2 Complete ✅

By reaching this point, you've planned:

* Development environment
* Project architecture
* Repository strategy
* Engine configuration
* Folder structure
* Plugin policy
* Asset database
* Debug toolkit
* Build system
* Documentation
* Automation
* First playable prototype

This provides a strong foundation for implementation.

# Next Major Phase

The next logical step is **Stage 3 – Core Engine & Gameplay Systems**. Rather than continuing with high-level planning, Stage 3 should focus on implementing systems one by one in a dependency-aware order:

1. Bootstrap & Game Lifecycle
2. Scene Management
3. Input System
4. Third-Person Character Controller
5. Camera System
6. Interaction System
7. Save/Load System
8. Inventory Foundation
9. Time System
10. Weather Foundation

Each completed stage should leave you with a working, testable feature that becomes part of the final game instead of being a temporary prototype.
