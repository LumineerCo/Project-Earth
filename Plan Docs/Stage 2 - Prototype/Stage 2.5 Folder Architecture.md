Excellent. Stage **2.5** is one of the most important technical stages. A poorly organized folder structure can make a large game nearly impossible to maintain. The goal is to design a structure that can still work when the project grows to **50,000–100,000+ files** over several years.

---

# Stage 2.5 – Folder Architecture (AAA Project Structure)

## Objective

Create a **modular, scalable, maintainable** folder architecture for a large 3D open-world game using only free tools.

## Design Principles

Every folder should follow these rules:

* **Single responsibility**: One purpose per folder.
* **No duplicate assets**: One authoritative source.
* **Predictable paths**: Easy to find files.
* **Scalable**: New content should fit without reorganizing everything.
* **Data-driven**: Configuration separated from code.

---

# Phase 1 – Root Project Structure

```text
ProjectEarth/
│
├── .github/
├── addons/
├── assets/
├── autoload/
├── configs/
├── data/
├── docs/
├── editor/
├── exports/
├── localization/
├── scenes/
├── scripts/
├── shaders/
├── tests/
├── tools/
├── ui/
├── worlds/
├── mods/
├── cache/
└── backups/
```

### Purpose

| Folder       | Purpose                                    |
| ------------ | ------------------------------------------ |
| addons       | Godot plugins                              |
| assets       | Art, audio, textures, models               |
| autoload     | Global managers                            |
| configs      | Configuration files                        |
| data         | Gameplay databases                         |
| docs         | Documentation                              |
| editor       | Editor utilities                           |
| exports      | Build outputs                              |
| localization | Translation files                          |
| scenes       | Game scenes                                |
| scripts      | Game logic                                 |
| shaders      | GPU shaders                                |
| tests        | Automated tests                            |
| tools        | Development utilities                      |
| ui           | User interface                             |
| worlds       | World maps and regions                     |
| mods         | Future mod support                         |
| cache        | Temporary generated files (ignored by Git) |
| backups      | Local backups (ignored by Git)             |

---

# Phase 2 – Assets Architecture

```
assets/

├── animations/
├── audio/
├── characters/
├── clothing/
├── decals/
├── effects/
├── environments/
├── foliage/
├── furniture/
├── icons/
├── interiors/
├── materials/
├── models/
├── particles/
├── props/
├── roads/
├── sky/
├── terrain/
├── textures/
├── vehicles/
└── wildlife/
```

Each category should contain only production-ready assets.

---

# Phase 3 – Source Assets

Keep editable source files separate.

```
assets_source/

├── blender/
├── krita/
├── gimp/
├── audio/
├── reference/
└── scans/
```

Examples:

* `.blend`
* `.kra`
* `.xcf`
* `.wav` masters
* High-resolution references

Game-ready assets should be exported into `assets/`.

---

# Phase 4 – World Organization

```
worlds/

planet/

continents/

countries/

states/

cities/

districts/

blocks/

interiors/
```

A hierarchy like this matches the streamed-world design from your planning stages.

---

# Phase 5 – Scene Organization

```
scenes/

boot/

main/

menus/

player/

camera/

vehicles/

npc/

world/

weather/

missions/

interiors/

buildings/

ui/

debug/
```

Each scene should encapsulate one feature or location.

---

# Phase 6 – Script Organization

```
scripts/

core/

player/

camera/

npc/

vehicle/

world/

weather/

ui/

save/

audio/

economy/

inventory/

quests/

skills/

network/

debug/
```

Avoid large "miscellaneous" folders—organize by system.

---

# Phase 7 – Data Organization

Store gameplay configuration outside scripts.

```
data/

items/

vehicles/

npc/

jobs/

cities/

countries/

shops/

economy/

missions/

weather/

animals/

plants/

roads/
```

Possible formats:

* JSON
* CSV
* Godot Resources (`.tres`/`.res`)

Choose one format consistently for each type of data.

---

# Phase 8 – Documentation

```
docs/

GameDesign/

Technical/

Architecture/

Art/

Audio/

UI/

NPC/

Economy/

Vehicles/

World/

Roadmap/

Changelog/

MeetingNotes/
```

Documentation evolves with the project.

---

# Phase 9 – Configuration

```
configs/

graphics/

audio/

controls/

gameplay/

editor/

performance/
```

Keeping configuration separate allows easier testing and future settings menus.

---

# Phase 10 – Testing

```
tests/

unit/

integration/

performance/

save/

stress/

world/
```

Even if you begin with only a few tests, reserving the structure now encourages better quality later.

---

# Phase 11 – Naming Standards

Examples:

```
player_controller.gd

vehicle_sedan_compact.tscn

npc_shopkeeper_001.tscn

road_highway_curve_01.glb

building_apartment_small_02.tscn
```

Recommended conventions:

* lowercase
* underscores
* descriptive names
* avoid spaces
* avoid generic names like `test.gd` or `newscene.tscn`

---

# Phase 12 – Asset Metadata

Maintain a catalog (spreadsheet or database) with:

| Field    | Example                    |
| -------- | -------------------------- |
| Asset ID | VEH_0001                   |
| Name     | Compact Sedan              |
| Category | Vehicle                    |
| Source   | Poly Haven / Self-made     |
| License  | CC0 / MIT / etc.           |
| Version  | 1.0                        |
| Status   | Draft / Approved           |
| Author   | Your name or source author |

This helps manage licenses and updates over time.

---

# Phase 13 – Git Rules

Commit only source files.

Do **not** commit:

* Temporary caches
* Build outputs
* Editor-generated caches
* Log files
* OS-specific temporary files

Use `.gitignore` to exclude these.

---

# Phase 14 – Free Resources

These references can help refine your architecture and workflow:

### Official Documentation

* [Godot Documentation](https://docs.godotengine.org?utm_source=chatgpt.com)
* [Godot Best Practices](https://docs.godotengine.org/en/stable/tutorials/best_practices/index.html?utm_source=chatgpt.com)

### Version Control

* [Git Documentation](https://git-scm.com/doc?utm_source=chatgpt.com)
* [GitHub Docs](https://docs.github.com?utm_source=chatgpt.com)

### Assets

* [Poly Haven](https://polyhaven.com?utm_source=chatgpt.com)
* [AmbientCG](https://ambientcg.com?utm_source=chatgpt.com)
* [Kenney Assets](https://kenney.nl/assets?utm_source=chatgpt.com)
* [Quaternius](https://quaternius.com?utm_source=chatgpt.com)

---

# Deliverables for Stage 2.5

By the end of this stage, you should have:

* ✅ Complete root folder architecture
* ✅ Asset folder hierarchy
* ✅ Source asset separation
* ✅ Scene organization
* ✅ Script organization
* ✅ Data organization
* ✅ Documentation structure
* ✅ Configuration structure
* ✅ Testing structure
* ✅ Naming conventions
* ✅ Asset metadata strategy
* ✅ Git folder rules

---

# Recommendation Before Stage 2.6

Before adding plugins, I'd introduce a **Core Framework** milestone that defines reusable systems every future feature will depend on:

1. Event Bus (system-to-system communication)
2. Logger (debugging and diagnostics)
3. Configuration Manager
4. Resource Manager
5. Object Pooling
6. Save Manager
7. Scene Manager
8. Time Manager
9. Settings Manager
10. Developer Console

Building these first gives you a stable foundation before implementing gameplay systems like player movement, AI, vehicles, or world streaming.
