# Project-Earth

Project Earth is a realistic, living, Earth-inspired open-world game concept where NPCs have purpose, cities feel alive, and players can build their own lives through exploration, work, travel, business, and adventure.

Owner: Bablu K Sahu

Company: LumineerCo

## Design Documentation

- [Game Design Document](docs/GDD.md)
- [Engineering Plan](docs/ENGINEERING_PLAN.md)
- [Phased Implementation Plan](docs/IMPLEMENTATION_PLAN.md)
- [Phase Files](docs/phases/README.md)
- [Asset License Registry](ASSET_LICENSES.md)


## Phase 0 Development

Run the data validator before committing game data changes:

```bash
python tools/validators/validate_data.py
python tools/validators/validate_project_files.py
python tools/validators/validate_phase_requirements.py
```

Open `game/project.godot` in Godot 4.x to run the current shell scene locally. Phase 1 controls are documented in `game/README.md`.
