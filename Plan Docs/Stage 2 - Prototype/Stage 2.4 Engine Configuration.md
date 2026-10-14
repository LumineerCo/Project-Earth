Excellent. This stage is where we configure the engine **before writing gameplay code**. Many settings are difficult to change later without affecting the whole project, so it's worth planning them carefully.

For a solo developer making a large Earth-inspired open-world game, the priorities are:

* Stable performance
* Easy maintenance
* Scalable architecture
* Free and open-source tools only

---

# Stage 2.4 – Engine Configuration

## Goal

Configure the engine once so every future scene, asset, and system follows the same standards.

---

# Step 1 – Choose a Stable Engine Version

Use the latest **stable** release of Godot Engine rather than development or beta builds unless you specifically need a new feature.

### Recommended Renderer

**Forward+**

Why:

* Best choice for desktop 3D
* Supports clustered lighting
* Good balance of quality and performance
* Well suited to open-world environments

Compatibility mode can be considered later for very low-end hardware.

---

# Step 2 – Project Settings

Document every important change from the default configuration.

## Application

Configure:

* Project name
* Version
* Company name (optional)
* Application icon
* Window title

Example:

```text
Project Name:
Project Earth

Version:
0.0.1-alpha
```

---

# Step 3 – Window Configuration

Plan for multiple display sizes.

Recommended:

* Resizable window
* Borderless fullscreen option
* Fullscreen option
* V-Sync toggle
* UI scaling support

Avoid locking the game to a single resolution.

---

# Step 4 – Rendering Configuration

For an open-world project, decide quality targets early.

Examples of settings to review:

### Lighting

* Directional sunlight
* Dynamic shadows
* Shadow distance
* Shadow filtering

### Environment

* HDR
* Tonemapping
* Ambient lighting
* Reflection probes
* Fog

### Materials

Use Physically Based Rendering (PBR):

* Albedo
* Normal
* Roughness
* Metallic
* Ambient Occlusion

Keeping all materials consistent makes the world look more cohesive.

---

# Step 5 – Physics Configuration

Decide standards before creating gameplay.

Examples:

* Collision layers
* Collision masks
* Physics timestep
* Gravity
* Character controller conventions

These settings should stay consistent throughout the project.

---

# Step 6 – Input System

Create actions instead of hardcoding keys.

Examples:

```text
move_forward

move_backward

move_left

move_right

jump

run

walk

interact

inventory

phone

pause

map

vehicle_enter

vehicle_exit

camera_zoom
```

This makes rebinding controls much easier.

---

# Step 7 – Localization

Enable localization from the beginning.

Initial languages:

* English
* Hindi

Future additions:

* Spanish
* French
* German
* Japanese
* Arabic
* Portuguese

Keep all user-facing text in translation resources rather than inside scripts.

---

# Step 8 – Audio Configuration

Organize audio into buses.

Suggested layout:

```text
Master

Music

Ambient

Effects

UI

Dialogue

Vehicles

Weather

Nature
```

This lets players adjust categories independently.

---

# Step 9 – Layer Planning

Plan rendering and physics layers before importing assets.

Example categories:

### Physics

* World
* Player
* NPC
* Vehicles
* Buildings
* Water
* Interactive Objects
* Triggers

### Navigation

* Pedestrians
* Vehicles
* Boats
* Wildlife

Consistent layer usage simplifies debugging.

---

# Step 10 – World Units

Adopt a single measurement standard.

Recommended:

* **1 engine unit = 1 meter**

Benefits:

* Easier asset imports
* Realistic physics
* Consistent vehicle sizes
* Predictable animations

---

# Step 11 – Asset Import Rules

Define import presets by asset type.

### Models

* Generate LODs where appropriate
* Generate collision only when needed
* Preserve normals for high-quality shading

### Textures

* Compress appropriately
* Generate mipmaps
* Use suitable filtering

### Audio

* Separate music, voice, and effects
* Use consistent sample rates where practical

Having presets reduces repetitive work.

---

# Step 12 – Navigation Standards

Decide how navigation will work.

Separate navigation systems for:

* Citizens
* Vehicles
* Wildlife

This allows different movement rules without conflicts.

---

# Step 13 – Debug Configuration

Build developer tools into the project early.

Useful overlays:

* FPS
* Frame time
* Active NPC count
* Loaded chunks
* Memory usage
* Physics objects
* Active audio sources

These tools become invaluable during optimization.

---

# Step 14 – Performance Budgets

Define initial budgets before adding content.

Track items such as:

| Category           | Initial Goal      |
| ------------------ | ----------------- |
| Active NPCs        | Configurable      |
| Active vehicles    | Configurable      |
| Dynamic lights     | Limited per area  |
| Texture resolution | By asset category |
| Triangle count     | By asset category |
| Draw calls         | Monitor regularly |

These are starting points that should be adjusted after profiling real gameplay.

---

# Step 15 – Engine Plugins

Only install plugins that provide clear long-term value.

Possible categories:

* Terrain tools
* Import utilities
* Debugging
* Profiling
* Editor productivity

Avoid installing many plugins at once. Each dependency increases future maintenance.

---

# Step 16 – Quality Standards

Before merging any feature:

* Follows naming conventions
* Uses project folder structure
* Has documentation
* Uses correct collision layers
* Uses correct import settings
* Meets performance targets
* Passes testing

---

# Step 17 – Free Resources

Useful official references:

### Engine

* [Godot Documentation](https://docs.godotengine.org?utm_source=chatgpt.com)
* [Godot Best Practices](https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html?utm_source=chatgpt.com)
* [Godot Asset Library](https://godotengine.org/asset-library/asset?utm_source=chatgpt.com)

### 3D Content

* [Blender Manual](https://docs.blender.org/manual/en/latest/?utm_source=chatgpt.com)
* [Poly Haven](https://polyhaven.com?utm_source=chatgpt.com)
* [AmbientCG](https://ambientcg.com?utm_source=chatgpt.com)

### Performance & Design

* [Game Programming Patterns](https://gameprogrammingpatterns.com?utm_source=chatgpt.com)

---

# Deliverables for Stage 2.4

By the end of this stage, your project should have:

* ✅ Stable engine version selected
* ✅ Rendering strategy defined
* ✅ Physics conventions documented
* ✅ Input action map
* ✅ Audio bus structure
* ✅ Localization plan
* ✅ World measurement standard
* ✅ Asset import rules
* ✅ Navigation strategy
* ✅ Debug tool roadmap
* ✅ Performance budget framework
* ✅ Plugin policy

---

## Before Stage 2.5

I recommend inserting one more architectural stage before gameplay coding:

**Stage 2.5 – Core Framework & Service Architecture**

Instead of starting with the player controller immediately, we'll build reusable systems such as:

* Event Bus
* Service Locator (or dependency injection pattern)
* Scene Manager
* Save Manager
* Configuration Manager
* Resource Cache
* Object Pooling
* Logging System
* Settings Manager
* Time Manager

Building these foundations first will make later systems—player movement, AI, vehicles, weather, and economy—much cleaner and easier to maintain in a long-running project.
