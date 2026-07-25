# Project Earth Game Client

This is the Phase 2 Godot 4.x shell for Project Earth. It contains a main scene, player controller, interaction prototype, save/load manager, debug overlay, NPC manager, schedule-driven NPC agents, and original sample data used by the validators.

## Phase 0 Commands

```bash
python tools/validators/validate_data.py
python tools/validators/validate_project_files.py
python tools/validators/validate_phase_requirements.py
```

Open `game/project.godot` in Godot 4.x to run the shell scene locally.

## Phase 1 Controls

- `WASD`: move the player.
- `E`: interact with the nearest interactable.
- `F5`: save local state to `user://saves/slot_1.json`.
- `F9`: load local state if a save exists.
