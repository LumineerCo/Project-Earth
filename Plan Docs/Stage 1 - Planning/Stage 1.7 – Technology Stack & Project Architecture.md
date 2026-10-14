Excellent. From this stage onward, we're designing the **technical foundation** that the entire game will rely on. A good architecture will save hundreds of hours later.

---

# Stage 1.7 – Technology Stack & Project Architecture

## Objective

Build a **100% free, open-source, scalable, offline-friendly** development stack that a solo developer can use for years.

---

# Step 1 – Core Technology Stack

| Component        | Tool                 | Cost | Why                           |
| ---------------- | -------------------- | ---- | ----------------------------- |
| Game Engine      | Godot Engine         | Free | Main engine                   |
| 3D Modeling      | Blender              | Free | Models, animations            |
| Image Editing    | GIMP                 | Free | Textures                      |
| Digital Painting | Krita                | Free | Concept art                   |
| Audio Editing    | Audacity             | Free | Sound editing                 |
| Version Control  | GitHub + Git         | Free | Source backup & collaboration |
| Documentation    | Obsidian or Markdown | Free | GDD and notes                 |

---

# Step 2 – Project Folder Structure

A clean folder structure from day one:

```text
ProjectEarth/
│
├── Assets/
│   ├── Characters/
│   ├── Vehicles/
│   ├── Buildings/
│   ├── Roads/
│   ├── Nature/
│   ├── Audio/
│   ├── UI/
│   └── Materials/
│
├── Scenes/
│   ├── World/
│   ├── Cities/
│   ├── Interiors/
│   ├── Menus/
│   └── Missions/
│
├── Scripts/
│
├── Data/
│
├── Saves/
│
├── Localization/
│
├── Mods/
│
└── Docs/
```

---

# Step 3 – Scene Architecture

Instead of one huge scene:

```text
World
 ├── Country
 │
 ├── Region
 │
 ├── City
 │
 ├── District
 │
 └── Building Interior
```

Each scene loads only when required.

---

# Step 4 – Naming Convention

Consistent names reduce confusion.

Examples:

```
car_sedan_01
npc_shopkeeper_01
building_hospital_01
road_highway_01
tree_oak_large
```

---

# Step 5 – Data System

Store game data outside the code where possible.

Examples:

* NPC definitions
* Item database
* Vehicle specifications
* Shop inventory
* Mission data
* Weather settings
* Economy values

This makes balancing easier later.

---

# Step 6 – Save System

The save file should record:

* Player position
* Inventory
* Money
* Health
* Owned vehicles
* Owned properties
* Mission progress
* NPC relationships
* World changes
* Weather and time

---

# Step 7 – AI Architecture

Every NPC will have:

* Identity
* Home
* Workplace
* Daily schedule
* Friends/family
* Mood
* Skills
* Money
* Inventory

Long-term, this creates the feeling of a living world instead of static characters.

---

# Step 8 – Vehicle Architecture

Each vehicle stores:

* Brand (fictional)
* Model
* Type
* Fuel/Battery
* Damage
* Mileage
* Owner
* Insurance (optional gameplay)
* Maintenance history

---

# Step 9 – Building System

Buildings belong to categories such as:

* Residential
* Commercial
* Government
* Industrial
* Medical
* Educational
* Entertainment
* Religious
* Transport

Interiors can be added gradually instead of all at once.

---

# Step 10 – Modular Asset Rules

Create reusable parts:

* Doors
* Windows
* Roofs
* Walls
* Floors
* Stairs
* Furniture
* Street props

With enough modules, many unique buildings can be assembled efficiently.

---

# Step 11 – Localization

Design for multiple languages from the start.

Initial support:

* English
* Hindi

Future:

* Spanish
* Arabic
* French
* Japanese
* German
* Portuguese

---

# Step 12 – Mod Support (Future)

Plan a simple mod folder:

```text
Mods/
    Vehicles/
    Maps/
    Clothing/
    Missions/
    Audio/
```

This makes community expansion possible later.

---

# Step 13 – Backup Strategy

Never rely on one copy.

Recommended workflow:

* Local project folder
* Git repository
* Cloud backup (for example, Google Drive or GitHub)

---

# Step 14 – Free Resources

Useful free resources include:

* **Godot Asset Library** – Plugins and sample projects.
* **Poly Haven** – CC0 HDRIs, textures, and some models.
* **Kenney** – Free game assets for prototypes.
* **OpenGameArt** – Openly licensed art and audio (check each asset's license).
* **Mixamo** – Free character auto-rigging and animations for Adobe accounts.
* **Quaternius** – Free low-poly and prototype-ready assets.

---

# Step 15 – Development Workflow

Every feature follows the same cycle:

1. Design
2. Prototype
3. Test
4. Optimize
5. Polish
6. Document
7. Release

This helps avoid feature creep.

---

# Project Roadmap (Planning Phase)

We're treating the planning stage like a professional GDD. The next major sections are:

* ✅ Stage 1.1 – Project Vision
* ✅ Stage 1.2 – Planet & World Design
* ✅ Stage 1.3 – World Map Design
* ✅ Stage 1.4 – Continent Layout
* ✅ Stage 1.5 – Country & Political Design
* ✅ Stage 1.6 – World Scale & Streaming
* ✅ Stage 1.7 – Technology Stack & Architecture

## Before Stage 2

I recommend adding one more planning section:

**Stage 1.8 – Asset Pipeline & Content Creation**

This is where we'll define:

* How to obtain **100% legal free assets**
* How to create realistic characters
* How to build cities efficiently
* Terrain generation workflow
* Texture workflow
* Animation pipeline
* Audio pipeline
* Licensing checklist (CC0, CC BY, GPL, etc.)
* AI-assisted asset generation (where legally appropriate)
* Quality standards for every asset

That stage will become your **production manual**, ensuring every future model, texture, animation, and sound fits the same technical and artistic standards.
