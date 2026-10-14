Excellent. Stage **2.7** is where we build the **Asset Database**, which will become the backbone of your project. Large open-world games don't just store files in folders—they maintain structured metadata for every asset so developers can search, validate, update, and audit them.

Since your project targets a **₹0 budget** with **free and open-source tools**, we'll design a system that starts simple but can scale.

---

# Stage 2.7 – Asset Database & Asset Management System

## Objective

Create a centralized asset management system that tracks:

* Every 3D model
* Every texture
* Every sound
* Every animation
* Every material
* Every UI icon
* Every license
* Every version
* Every dependency

This database should answer questions like:

* Where did this asset come from?
* What license does it use?
* Which scenes use it?
* Is there a newer version?
* Is it optimized?
* Can it be removed safely?

---

# Phase 1 – Asset Categories

Every asset belongs to exactly one primary category.

```text id="3xwq1d"
Characters
Vehicles
Buildings
Roads
Nature
Terrain
Water
Sky
Props
Furniture
Clothing
Weapons (optional)
Animals
Audio
Music
UI
Icons
Animations
Particles
Materials
Shaders
Fonts
Localization
```

Subcategories can be added later.

---

# Phase 2 – Asset ID System

Every asset receives a permanent ID.

Examples:

```text id="5pr7qs"
CHR_000001

VEH_000001

BLD_000001

TRE_000001

AUD_000001

MAT_000001

UI_000001

ANM_000001
```

Once assigned, the ID never changes—even if the filename does.

---

# Phase 3 – Asset Metadata

Track standardized fields for every asset.

| Field       | Example                       |
| ----------- | ----------------------------- |
| Asset ID    | VEH_000045                    |
| Name        | Compact Sedan                 |
| Category    | Vehicle                       |
| Subcategory | Civilian Car                  |
| Version     | 1.2                           |
| Author      | Your name or original creator |
| Source      | Self-made / external source   |
| License     | CC0, CC BY, MIT, etc.         |
| File Path   | Project location              |
| Status      | Draft / Approved / Deprecated |
| Created     | Date                          |
| Updated     | Date                          |
| Notes       | Optional comments             |

---

# Phase 4 – Technical Metadata

For 3D assets, also record:

* Polygon count
* Vertices
* Texture resolution
* Number of materials
* Collision available
* LOD levels
* Physics setup
* Animation count
* File size

For audio:

* Sample rate
* Bit depth
* Duration
* Format
* Channels (mono/stereo)

---

# Phase 5 – Folder Structure

```text id="bmv6t9"
AssetDatabase/

Metadata/

Licenses/

Preview/

Reports/

Validation/

Exports/
```

Each folder has a specific responsibility.

---

# Phase 6 – Preview Images

Generate thumbnail previews.

Example:

```text id="4lkhwj"
VEH_000001.png

CHR_000145.png

BLD_000342.png
```

Visual previews make searching much faster.

---

# Phase 7 – License Tracking

Maintain a separate license record.

Fields:

* Asset ID
* License
* Attribution required
* Commercial use allowed
* Modification allowed
* Source URL
* Author
* Proof of license (if available)

This simplifies future audits.

---

# Phase 8 – Dependency Tracking

Record where assets are used.

Example:

```text id="up2twb"
VEH_000001

↓

Vehicle Scene

↓

Traffic System

↓

Garage

↓

Mission 12
```

This prevents accidentally deleting assets still in use.

---

# Phase 9 – Quality Status

Suggested workflow:

```text id="r1fbdf"
Concept

↓

Imported

↓

Optimized

↓

Tested

↓

Approved

↓

Released

↓

Deprecated
```

Every asset should have a current status.

---

# Phase 10 – Versioning

Example:

```text id="w7jm0e"
Tree

v1.0

↓

v1.1

↓

v2.0
```

Keep old versions archived until you're confident they're no longer needed.

---

# Phase 11 – Validation Checklist

Before approving an asset:

* Correct naming
* Correct scale
* Pivot verified
* Collision verified
* LODs checked (if applicable)
* Textures assigned
* License documented
* Performance acceptable

---

# Phase 12 – Recommended Free Tools

A simple workflow can be built with:

| Purpose           | Free Tool        |
| ----------------- | ---------------- |
| Spreadsheet       | LibreOffice Calc |
| Cloud spreadsheet | Google Sheets    |
| Embedded database | SQLite           |
| Structured text   | JSON / CSV       |
| Version control   | Git + GitHub     |

As the project grows, you can migrate from spreadsheets to SQLite while keeping the same asset IDs.

---

# Phase 13 – Reports

Generate reports such as:

* Missing licenses
* Duplicate assets
* Large texture files
* Missing LODs
* Unused assets
* Broken references
* Missing thumbnails

These reports help keep the project healthy.

---

# Phase 14 – Backup Strategy

Keep at least:

```text id="8x2m7g"
Asset Files

↓

Metadata

↓

License Records

↓

Preview Images

↓

Database Backup
```

Back up metadata alongside the assets themselves.

---

# Phase 15 – Free Resources

Useful references:

* [Godot Documentation – Importing Assets](https://docs.godotengine.org/en/stable/tutorials/assets_pipeline/index.html?utm_source=chatgpt.com)
* [Blender Manual](https://docs.blender.org/manual/en/latest/?utm_source=chatgpt.com)
* [Poly Haven](https://polyhaven.com?utm_source=chatgpt.com)
* [AmbientCG](https://ambientcg.com?utm_source=chatgpt.com)
* [OpenGameArt](https://opengameart.org?utm_source=chatgpt.com)
* [Creative Commons Licenses](https://creativecommons.org/licenses/?utm_source=chatgpt.com)

---

# Long-Term Vision

As your game grows, the Asset Database can evolve into a full **Asset Management Dashboard** with features like:

* Asset search
* Thumbnail gallery
* License browser
* Dependency graph
* Performance analyzer
* Duplicate finder
* Automatic validation
* Import queue
* Version history
* Export tools

---

# Deliverables for Stage 2.7

By the end of this stage, you'll have:

* ✅ Asset ID system
* ✅ Category hierarchy
* ✅ Metadata standard
* ✅ Technical metadata fields
* ✅ License tracking process
* ✅ Dependency tracking model
* ✅ Asset lifecycle workflow
* ✅ Validation checklist
* ✅ Reporting strategy
* ✅ Backup plan
* ✅ Scalable database design

---

## Recommendation Before Stage 2.8

Instead of immediately creating gameplay features, I recommend making **Stage 2.8 – Debug Framework & Developer Toolkit** much more ambitious.

Rather than a simple FPS counter, we'll design an in-game developer toolkit with:

* Debug console
* World inspector
* Asset inspector
* Chunk streaming visualizer
* NPC debugger
* Vehicle debugger
* Pathfinding visualizer
* Memory monitor
* Performance profiler
* Time/weather controls
* Teleport tool
* Spawn manager
* Save-state manager
* Screenshot mode

These tools don't appear in the final game, but they dramatically speed up development and testing—especially for a large open-world project.
