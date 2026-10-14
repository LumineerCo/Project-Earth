Excellent. This is the point where your project changes from an idea into an actual game project.

Because your goal is a **large Earth-inspired open-world game**, we won't just click **"New Project"** in Godot. We'll design the project so it can still be organized after years of development.

---

# Stage 2.3 – Game Project Setup (AAA Foundation)

## Goal

Create a **professional, scalable Godot project** that can eventually support:

* 🌍 Massive streamed world
* 🚶 Thousands of NPCs
* 🚗 Vehicles
* 🏠 Buildings
* 🌦️ Weather
* 🌙 Day/Night
* 💾 Save System
* 💰 Economy
* 🗺️ Modular maps
* 🔧 Mod support
* 🌐 Future multiplayer support (optional)

---

# Phase 1 – Create the Project

## Engine Choice

Use the latest **stable** version of Godot Engine (avoid beta builds for a long-term project unless you specifically need a new feature).

Suggested project information:

```
Project Name
Project Earth

Renderer
Forward+

Language
GDScript initially
(C# modules can be added later if needed)
```

Starting with GDScript keeps iteration fast for a solo developer.

---

# Phase 2 – Root Directory

The project should begin with a predictable structure.

```text
ProjectEarth/

├── addons/
├── assets/
├── autoload/
├── configs/
├── data/
├── docs/
├── editor/
├── localization/
├── scenes/
├── scripts/
├── shaders/
├── tests/
├── tools/
├── ui/
└── worlds/
```

---

# Phase 3 – Assets Folder

Separate source assets from game-ready assets.

```text
assets/

├── source/
│   ├── blender/
│   ├── textures/
│   ├── audio/
│   └── concepts/
│
├── imported/
│
├── optimized/
│
└── generated/
```

This lets you regenerate optimized assets without losing originals.

---

# Phase 4 – Scene Hierarchy

Think of scenes as LEGO bricks.

```text
scenes/

boot/

menus/

player/

camera/

vehicles/

npc/

buildings/

world/

weather/

ui/

missions/

interiors/

tools/
```

Each folder should contain self-contained scenes with minimal dependencies.

---

# Phase 5 – Script Architecture

Organize scripts by responsibility rather than by file type.

```text
scripts/

core/

player/

world/

npc/

vehicle/

ui/

audio/

network/

save/

economy/

weather/

debug/

editor/
```

Avoid putting unrelated logic into one large script.

---

# Phase 6 – Data Folder

Store configurable data separately.

```text
data/

items/

vehicles/

npc/

shops/

jobs/

weather/

roads/

cities/

countries/

missions/

economy/
```

Using external data makes balancing and localization easier.

---

# Phase 7 – Autoloads (Global Systems)

Only truly global systems should be autoloaded.

Examples:

* GameManager
* SaveManager
* AudioManager
* SettingsManager
* LocalizationManager
* SceneManager
* TimeManager
* WeatherManager
* EventBus

Keep the number of global singletons small to reduce coupling.

---

# Phase 8 – World Structure

We'll design the world hierarchically.

```text
World

↓

Continent

↓

Country

↓

State

↓

City

↓

District

↓

Block

↓

Building

↓

Room
```

This matches the planning work you've already completed.

---

# Phase 9 – Scene Loading

Never keep the entire world loaded.

Instead:

```
Player moves

↓

Load nearby districts

↓

Unload distant districts

↓

Keep save data

↓

Continue streaming
```

Streaming by districts or chunks is a scalable approach for open-world games.

---

# Phase 10 – Project Settings

Configure these early:

## Display

* Window mode
* Resolution scaling
* V-Sync options

## Input

* Keyboard
* Mouse
* Controller
* Future gamepad layouts

## Physics

* Fixed timestep
* Layer definitions
* Collision masks

## Rendering

* Shadows
* LOD distances
* Texture filtering

Document every non-default setting so the project is reproducible.

---

# Phase 11 – Collision Layers

Plan them before creating assets.

Example categories:

* Player
* NPC
* Vehicles
* Buildings
* World
* Water
* Items
* Projectiles (if used)
* Triggers
* UI interaction

Consistent collision rules prevent debugging headaches later.

---

# Phase 12 – Input Map

Create logical action names instead of referencing keys directly.

Examples:

```
move_forward

move_backward

move_left

move_right

jump

interact

run

crouch

inventory

map

phone

pause

vehicle_enter

vehicle_exit
```

This makes rebinding controls straightforward.

---

# Phase 13 – Performance Budget

Establish budgets before content creation.

Examples to track:

* Maximum active NPCs per district
* Maximum traffic density
* Texture memory targets
* Polygon budgets by asset category
* Shadow-casting lights
* Audio channels

These numbers can be adjusted as you profile real hardware.

---

# Phase 14 – Development Tools

Useful built-in tools to create later:

* FPS monitor
* Chunk visualizer
* Collision viewer
* NPC path viewer
* Spawn manager
* Time controls
* Weather controls
* Teleport tool

Developer tools save enormous amounts of testing time.

---

# Phase 15 – Quality Checklist

Every new feature should satisfy:

* Folder location follows standards
* Naming convention followed
* Documentation updated
* Performance checked
* Save/load tested
* Error logging reviewed
* Works independently where appropriate

---

# Phase 16 – Free Resources

For this stage, focus on official documentation and well-established free resources:

### Engine

* [Godot Documentation](https://docs.godotengine.org?utm_source=chatgpt.com)
* [Godot Asset Library](https://godotengine.org/asset-library/asset?utm_source=chatgpt.com)

### Art

* [Blender Manual](https://docs.blender.org/manual/en/latest/?utm_source=chatgpt.com)
* [Poly Haven](https://polyhaven.com?utm_source=chatgpt.com)
* [AmbientCG](https://ambientcg.com?utm_source=chatgpt.com)

### Learning

* [GDQuest](https://www.gdquest.com?utm_source=chatgpt.com)
* [KidsCanCode Godot Tutorials](https://kidscancode.org/godot_recipes/?utm_source=chatgpt.com)

---

# Deliverables for Stage 2.3

By the end of this stage, you should have:

* ✅ Godot project created
* ✅ Professional folder structure
* ✅ Asset pipeline folders
* ✅ Scene hierarchy
* ✅ Script architecture
* ✅ Data organization
* ✅ Global manager plan
* ✅ Collision layer plan
* ✅ Input action map
* ✅ Initial performance budgets
* ✅ Development tool roadmap

---

## Before Stage 2.4

Rather than immediately changing engine settings, I recommend inserting a foundational architecture stage:

**Stage 2.3A – Core System Architecture**

We'll design the communication between every major system:

* Player
* World Streaming
* NPC AI
* Vehicles
* Inventory
* Economy
* Weather
* Time
* Missions
* UI
* Save System
* Audio

The goal is to define clear interfaces and dependencies before implementation. For a project of this scale, that architectural layer will make future features much easier to add and maintain.
