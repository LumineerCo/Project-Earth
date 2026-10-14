Excellent. **Stage 2.9** is where we automate repetitive tasks. For a solo developer, automation is like having an extra team member: it catches mistakes early and ensures every build is created the same way.

Since your goals are **₹0 budget**, **free/open-source tools**, and **GitHub-hosted development**, we'll design a pipeline that uses free services where practical.

> **Note:** Free CI services have usage limits, so the pipeline should be efficient and avoid unnecessary runs.

---

# Stage 2.9 – Build System & Continuous Integration (CI)

## Objective

Create an automated pipeline that can:

* Validate the project
* Run tests
* Check assets
* Build the game
* Package releases
* Archive builds
* Generate version information
* Publish development builds

---

# Build Pipeline Overview

```text
Developer
      │
      ▼
Git Commit
      │
      ▼
GitHub Repository
      │
      ▼
CI Pipeline
      │
 ┌────┴───────────────────────────┐
 │ Validate                       │
 │ Lint                           │
 │ Asset Checks                   │
 │ Run Tests                      │
 │ Create Build                   │
 │ Package                        │
 │ Generate Release Notes         │
 │ Upload Artifact                │
 └────────────────────────────────┘
      │
      ▼
Testing / Release
```

---

# Phase 1 – Versioning

Adopt semantic versioning.

Examples:

```text
0.0.1

0.1.0

0.2.0

1.0.0
```

Suggested meanings:

* **Major** – Breaking changes or major milestones.
* **Minor** – New features.
* **Patch** – Bug fixes.

---

# Phase 2 – Build Types

Define build targets.

### Development

* Debug symbols
* Developer console
* Debug overlay
* Logging enabled

### Testing

* Optimized
* Test tools available
* Internal testing

### Release

* Optimized
* Debug tools removed or disabled
* Final assets

---

# Phase 3 – Build Targets

Initially support:

* Windows
* Linux

Future additions:

* macOS
* Android
* Steam Deck
* Console platforms (if pursued)

---

# Phase 4 – Project Validation

Before building, automatically check:

* Missing resources
* Broken scene references
* Duplicate asset IDs
* Invalid filenames
* Missing localization keys
* Missing documentation entries (if required)

Fail the build if critical issues are found.

---

# Phase 5 – Asset Validation

Review imported assets for common problems.

Examples:

* Oversized textures
* Missing materials
* Missing collision
* Missing LODs (when required)
* Missing metadata
* Missing license information

Automated reports make it easier to spot issues early.

---

# Phase 6 – Code Quality

Run static checks where possible.

Goals:

* Detect syntax errors
* Identify unused code
* Highlight warnings
* Maintain consistent formatting

Keep these checks fast so they run on every change.

---

# Phase 7 – Automated Testing

As the project grows, categorize tests.

```text
Tests
│
├── Unit
├── Integration
├── Gameplay
├── Save/Load
├── World Streaming
├── AI
├── Performance
└── Regression
```

Start small and expand gradually.

---

# Phase 8 – Build Packaging

Organize outputs consistently.

```text
Builds/

Windows/

Linux/

Archives/

Symbols/

ReleaseNotes/
```

Include version numbers in filenames to avoid confusion.

---

# Phase 9 – Release Notes

Generate release notes from commit history.

Include:

* New features
* Fixes
* Known issues
* Version number
* Build date

This helps track progress over time.

---

# Phase 10 – Changelog

Maintain a changelog.

Suggested sections:

```text
Added

Changed

Fixed

Removed

Known Issues
```

Update it with every milestone.

---

# Phase 11 – Continuous Integration Workflow

Typical workflow:

```text
Push Code
      ↓
Validate
      ↓
Run Tests
      ↓
Build
      ↓
Package
      ↓
Upload Artifacts
      ↓
Notify Success/Failure
```

Only proceed to the next step if the previous one succeeds.

---

# Phase 12 – Continuous Delivery (Future)

Later, you can extend the pipeline to:

* Create tagged releases
* Upload builds automatically
* Publish release notes
* Prepare downloadable packages

Delay full automation until your build process is stable.

---

# Phase 13 – Backup Strategy

Keep multiple copies of important outputs.

Recommended categories:

```text
Source Code

Assets

Build Artifacts

Documentation

Save Files
```

Combine local backups with a remote Git repository.

---

# Phase 14 – Free Toolchain

A practical free stack includes:

| Purpose           | Tool                                                                     |
| ----------------- | ------------------------------------------------------------------------ |
| Version Control   | Git                                                                      |
| Remote Repository | [GitHub](https://github.com?utm_source=chatgpt.com)                      |
| CI/CD             | [GitHub Actions](https://docs.github.com/actions?utm_source=chatgpt.com) |
| Game Engine       | Godot Engine                                                             |
| Build Automation  | Godot command-line export                                                |
| Documentation     | Markdown                                                                 |
| Issue Tracking    | GitHub Issues                                                            |

---

# Phase 15 – Build Security

Before publishing:

* Remove debug-only tools.
* Verify version numbers.
* Confirm licenses for included assets.
* Ensure no temporary files are packaged.
* Test installation on a clean system.

---

# Phase 16 – Performance Reports

For larger milestones, record:

* Build duration
* Package size
* Scene loading time
* Startup time
* Memory usage
* FPS benchmarks (representative hardware)

Comparing these reports over time helps detect regressions.

---

# Phase 17 – Milestone Pipeline

Example lifecycle:

```text
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

Each milestone should have its own tagged build and changelog.

---

# Phase 18 – Free Learning Resources

Useful official references:

* [GitHub Actions Documentation](https://docs.github.com/actions?utm_source=chatgpt.com)
* [Godot Export Documentation](https://docs.godotengine.org/en/stable/tutorials/export/index.html?utm_source=chatgpt.com)
* [Git Documentation](https://git-scm.com/doc?utm_source=chatgpt.com)

---

# Deliverables for Stage 2.9

By the end of this stage, your development plan includes:

* ✅ Versioning strategy
* ✅ Build types
* ✅ Platform targets
* ✅ Validation pipeline
* ✅ Asset verification
* ✅ Code quality checks
* ✅ Automated testing structure
* ✅ Build packaging
* ✅ Release note workflow
* ✅ Changelog process
* ✅ CI workflow
* ✅ Backup strategy
* ✅ Build security checklist
* ✅ Performance reporting plan

---

# Before Stage 2.10

Rather than focusing only on documentation, I'd recommend making **Stage 2.10 – Development Documentation System** a searchable internal knowledge base.

It would include:

* System architecture diagrams
* API documentation
* Coding standards
* Asset standards
* UI guidelines
* World-building documentation
* NPC design documents
* Economy documentation
* Quest documentation
* Testing procedures
* Troubleshooting guides
* Decision logs (why important technical choices were made)

Treating documentation as part of the project—not an afterthought—makes long-term solo development much easier.
