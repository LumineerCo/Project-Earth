# Development Automation Tools

> Project Earth — Automation Toolkit
> Stage 2.11 — Development Automation

This folder contains scripts that automate repetitive development tasks. Run them from the editor console or integrate them into CI/build pipelines.

---

## Tools Overview

### `automation_manager.gd`

Central task coordinator. Registers all automation tools and provides a common execution interface.

**Usage:**
```gdscript
var mgr = load("res://tools/automation_manager.gd").new()
mgr.run_task("validate_data")      # Run one task
mgr.run_all()                       # Run all registered tasks
```

**Tasks:**
- `validate_data` — Validate all JSON data files
- `asset_inventory` — Scan and catalog assets
- `plan_coverage_audit` — Audit Plan Docs file references against actual project files

**API:**
- `register_task(name, description, script_path, enabled)` — Register a new task
- `run_task(name) -> bool` — Run a single task
- `run_all()` — Run all enabled tasks
- `list_tasks() -> Array[String]` — List available tasks

---

### `validate_data.gd`

Validates all JSON data files in `data/` against their schemas.

**Usage:**
```gdscript
var validator = load("res://tools/validate_data.gd").new()
validator.validate_all()
validator.print_report()
```

**What it checks:**
- Valid JSON syntax
- Required fields present
- Field types match schema
- No orphaned references

**Output:**
- Count of valid records
- List of errors and warnings
- Per-folder statistics

**Supported schemas:**
- `data/cities/` — city records
- `data/countries/` — country records
- `data/items/` — item definitions
- `data/jobs/` — job definitions
- `data/shops/` — shop records
- `data/vehicles/` — vehicle templates

---

### `asset_inventory.gd`

Scans `assets/` folder and generates an inventory of all art, audio, and prop files.

**Usage:**
```gdscript
var inventory = load("res://tools/asset_inventory.gd").new()
inventory.scan()
inventory.print_summary()
```

**What it tracks:**
- Total file count
- Files per category (animations, audio, models, etc.)
- Files per extension (.glb, .png, .ogg, etc.)
- Duplicate filenames (warning)
- Missing references (placeholder)

**Output:**
- Asset count by category and type
- Warning list for duplicates

---

## Adding New Tools

1. Create a new script `res://tools/my_tool.gd` extending `Node`:
   ```gdscript
   extends Node
   class_name MyTool
   
   func scan() -> void:
       # Implement your logic
       pass
   
   func print_summary() -> void:
       # Print results
       pass
   ```

2. Register it in `AutomationManager._register_default_tasks()`:
   ```gdscript
   register_task("my_task", "Description", "res://tools/my_tool.gd", true)
   ```

3. Verify it has no errors:
   ```
   editor console > var t = load("res://tools/my_tool.gd").new()
   ```

---

## Future Tools (Stage 2.11+)

- **lint_data.gd** — Lint JSON for common mistakes (missing IDs, typos)
- **generate_docs.gd** — Auto-generate asset catalogs and indexes
- **check_assets.gd** — Verify all referenced assets exist
- **validate_schema.gd** — Compare data against formal schema definitions
- **report_generator.gd** — Generate markdown reports of all checks
- **backup_manager.gd** — Automated incremental backups
- **performance_profiler.gd** — Profile game performance and memory

---

## Editor Integration

These tools are designed to run from the Godot editor console for immediate feedback during development. In the future (Stage 2.9), they will be integrated into CI/build workflows.

### Running from Console

```
# Open Godot, open the Script editor, go to the Debug tab
> var mgr = load("res://tools/automation_manager.gd").new()
> mgr.run_task("validate_data")
```

Output will print to the Godot console.
