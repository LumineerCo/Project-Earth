Excellent. This is the first stage where we set up the project's long-term development workflow. A good repository structure and version-control strategy can save countless hours as the project grows.

---

# Stage 2.2 – Repository & Version Control

## Objective

Create a **professional, scalable, free** version-control system for an open-world game that may eventually contain tens of thousands of files.

We'll use only free tools.

## Core Stack

| Purpose           | Tool                                                  | Why                                                          |
| ----------------- | ----------------------------------------------------- | ------------------------------------------------------------ |
| Version Control   | Git                                                   | Industry standard, free, distributed                         |
| Remote Repository | [GitHub](https://github.com?utm_source=chatgpt.com)   | Free private/public repositories, issue tracking, releases   |
| Large Files       | [Git LFS](https://git-lfs.com?utm_source=chatgpt.com) | Designed for large binary assets such as models and textures |
| Documentation     | Markdown                                              | Simple, version-controlled documentation                     |

---

# Step 1 – Repository Strategy

Don't keep everything in one huge repository.

Instead, separate responsibilities.

## Repository Structure

```text
Project-Earth/

├── game-client/
├── game-assets/
├── game-documentation/
├── game-tools/
├── game-server/          (future)
├── website/              (future)
├── launcher/             (future)
├── mod-sdk/              (future)
└── localization/
```

### Why?

Different parts of the project evolve at different speeds.

For example:

* Documentation changes daily.
* Assets become very large.
* Game code changes frequently.
* Website is independent.

Keeping them separate reduces download size and simplifies maintenance.

---

# Step 2 – Repository Roles

## game-client

Contains:

* Godot project
* Scripts
* Scenes
* UI
* Gameplay systems
* Save system

No raw Blender files here.

---

## game-assets

Contains:

* Blender projects
* Textures
* HDRIs
* Audio masters
* Source PSD/XCF files

This repository will likely become the largest.

---

## game-documentation

Contains:

* Game Design Document
* Production Bible
* World Bible
* NPC Bible
* Vehicle Bible
* Roadmaps
* Changelogs
* Architecture diagrams

Using Markdown makes documents easy to diff and review.

---

## game-tools

Contains utilities such as:

* Asset converters
* Import scripts
* Map generators
* Validation tools
* Export helpers

---

# Step 3 – Branching Strategy

For a solo developer, keep it simple.

```text
main
│
├── develop
│
├── feature-player
├── feature-vehicles
├── feature-ai
├── feature-ui
├── feature-world
└── hotfix
```

### Purpose

* **main** → stable versions
* **develop** → integration branch
* **feature-*** → one feature at a time
* **hotfix** → urgent fixes

---

# Step 4 – Commit Rules

Good commit messages help you understand history months later.

Examples:

```
Add player movement

Fix inventory save bug

Improve road generation

Optimize terrain loading

Update NPC schedules
```

Avoid messages like:

```
update

fix

changes

new

test
```

---

# Step 5 – Release Tags

Use semantic versioning.

Examples:

```
v0.0.1

v0.1.0

v0.2.0

v1.0.0
```

Example roadmap:

```
v0.1

Player

Camera

Terrain

Save System
```

```
v0.2

Vehicle

NPC

Weather

Time
```

---

# Step 6 – Folder Rules

Inside the game repository:

```text
addons/

assets/

data/

docs/

fonts/

materials/

models/

scenes/

scripts/

shaders/

sounds/

textures/

ui/
```

Keep generated files and source files separate whenever possible.

---

# Step 7 – Git Ignore

Never commit:

* Temporary exports
* Cache files
* Build outputs
* Logs
* Editor-specific temporary files

Most engines, including Godot, provide recommended `.gitignore` templates.

---

# Step 8 – Large Asset Workflow

3D games include large files.

Examples:

* `.blend`
* `.psd`
* `.xcf`
* High-resolution textures
* Audio masters

Git LFS is designed for these types of assets and keeps the main repository manageable.

---

# Step 9 – Documentation Standards

Every repository should contain:

```
README.md

LICENSE

CHANGELOG.md

CONTRIBUTING.md

ROADMAP.md
```

Even as a solo developer, these files make the project easier to understand later.

---

# Step 10 – Issue Tracking

Use GitHub Issues to organize work.

Suggested labels:

* Bug
* Feature
* Documentation
* Art
* Audio
* Performance
* UI
* AI
* World
* Vehicle
* NPC

You can also create milestones such as:

* Prototype
* Vertical Slice
* Alpha
* Beta
* Version 1.0

---

# Step 11 – Milestones

Suggested progression:

```
Prototype

↓

Vertical Slice

↓

Alpha

↓

Beta

↓

Release Candidate

↓

Version 1.0
```

---

# Step 12 – Backup Strategy

Follow the **3-2-1 backup rule**, which is widely recommended for important projects:

* **3 copies** of your data.
* **2 different storage types** (for example, your PC and an external drive).
* **1 copy stored off-site** (for example, GitHub or cloud storage).

This greatly reduces the risk of losing months of work.

---

# Step 13 – Free Resources

Useful official resources:

* [Git Documentation](https://git-scm.com/doc?utm_source=chatgpt.com)
* [GitHub Docs](https://docs.github.com?utm_source=chatgpt.com)
* [Git LFS Documentation](https://git-lfs.com?utm_source=chatgpt.com)
* [Godot Version Control Guide](https://docs.godotengine.org/en/stable/tutorials/best_practices/version_control_systems.html?utm_source=chatgpt.com)

---

# Deliverables for Stage 2.2

By the end of this stage, you should have:

* ✅ Git installed (when you have a development PC)
* ✅ GitHub account ready
* ✅ Repository structure planned
* ✅ Branching strategy defined
* ✅ Commit conventions established
* ✅ Version numbering system
* ✅ Documentation repository structure
* ✅ Backup strategy
* ✅ Issue and milestone workflow

## Recommendation Before Stage 2.3

Because this project is expected to become a very large open-world game, I'd recommend that **before creating the Godot project**, we spend one more technical stage on **System Architecture & Dependency Planning**.

That stage will define every core subsystem (player, AI, vehicles, world streaming, economy, UI, save system, networking for the future, etc.) and, more importantly, **how they communicate with each other**. Designing those interfaces early reduces the amount of refactoring needed as the project expands.
