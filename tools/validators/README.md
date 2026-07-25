# Validators

Run validators before committing game data changes. Validators should fail loudly when data is unsafe to load, references are missing, IDs are duplicated, or content violates zero-budget licensing rules.

```bash
python tools/validators/validate_data.py
```

Validate scene/project file references after editing Godot scene files:

```bash
python tools/validators/validate_project_files.py
python tools/validators/validate_phase_requirements.py
```
