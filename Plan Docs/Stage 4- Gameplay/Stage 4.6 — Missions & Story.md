# Stage 4.6 — Missions & Story

Missions give the player goals beyond free-roam. They range from simple fetch quests to multi-stage story arcs with branching outcomes.

---

## Goal
Create a mission system with objectives, rewards, story arcs, and a mission tracker accessible via the phone.

---

## Step 1 — Mission Types

| Type | Description | Example |
| :--- | :--- | :--- |
| **Fetch** | Retrieve an item and deliver it | "Bring coffee to the office" |
| **Delivery** | Transport goods between locations | "Deliver package to the marina" |
| **Escort** | Protect an NPC to a destination | "Walk Mrs. Chen home safely" |
| **Race** | Reach checkpoints before time runs out | "Taxi race across the city" |
| **Investigation** | Find clues and solve a mystery | "Find the missing person" |
| **Combat** | Defeat enemies or survive waves | "Defend the warehouse" |
| **Stealth** | Complete objectives without detection | "Sneak into the office building" |
| **Story** | Multi-stage narrative missions | "The Nova City Conspiracy" |

---

## Step 2 — Mission Data Model

### `MissionData.gd`

```gdscript
extends Resource
class_name MissionData

@export var mission_id: String = ""
@export var mission_name: String = ""
@export var description: String = ""
@export var mission_type: String = "fetch"
@export var is_story: bool = false
@export var story_arc: String = ""
@export var story_chapter: int = 1
@export var prerequisites: Array[String] = []  # Mission IDs that must be completed first
@export var objectives: Array[Dictionary] = []  # [{type, target, count, description}]
@export var rewards: Dictionary = {
    "money": 0,
    "xp": 0,
    "items": [],  # Array of item_ids
    "skill_xp": {},  # {skill_name: amount}
}
@export var time_limit: float = 0.0  # 0 = no limit
@export var giver_npc_id: String = ""
@export var giver_location: String = ""
```

---

## Step 3 — Mission Manager

### `MissionManager.gd` (Autoload)

```gdscript
extends Node

signal mission_accepted(mission_id: String)
signal mission_completed(mission_id: String)
signal mission_failed(mission_id: String)
signal objective_updated(mission_id: String, objective_index: int, progress: int)
signal mission_progress_changed

var all_missions: Dictionary = {}  # mission_id -> MissionData
var active_missions: Array[String] = []
var completed_missions: Array[String] = []
var failed_missions: Array[String] = []
var objective_progress: Dictionary = {}  # mission_id -> Array[int]

func _ready() -> void:
    _load_missions()

func _load_missions() -> void:
    var dir = DirAccess.open("res://data/missions")
    if dir:
        _scan_mission_directory(dir)

func _scan_mission_directory(dir: DirAccess) -> void:
    dir.list_dir_begin()
    var file = dir.get_next()
    while file != "":
        if dir.current_is_dir() and file != "." and file != "..":
            var sub = DirAccess.open(dir.get_current_dir() + "/" + file)
            _scan_mission_directory(sub)
        elif file.ends_with(".tres"):
            var mission = load(dir.get_current_dir() + "/" + file) as MissionData
            if mission:
                all_missions[mission.mission_id] = mission
        file = dir.get_next()

func accept_mission(mission_id: String) -> bool:
    if not all_missions.has(mission_id): return false
    if mission_id in active_missions: return false
    if mission_id in completed_missions: return false
    
    var mission = all_missions[mission_id] as MissionData
    
    # Check prerequisites
    for prereq in mission.prerequisites:
        if prereq not in completed_missions:
            PhoneSystem.add_notification("Missions", "Locked",
                "Complete '%s' first" % all_missions[prereq].mission_name)
            return false
    
    active_missions.append(mission_id)
    objective_progress[mission_id] = []
    for i in mission.objectives.size():
        objective_progress[mission_id].append(0)
    
    mission_accepted.emit(mission_id)
    mission_progress_changed.emit()
    PhoneSystem.add_notification("Missions", "New Mission", mission.mission_name)
    return true

func update_objective(mission_id: String, objective_index: int, amount: int = 1) -> void:
    if mission_id not in active_missions: return
    if not objective_progress.has(mission_id): return
    if objective_index >= objective_progress[mission_id].size(): return
    
    var mission = all_missions[mission_id] as MissionData
    var objective = mission.objectives[objective_index]
    var target_count = objective.get("count", 1)
    
    objective_progress[mission_id][objective_index] += amount
    objective_updated.emit(mission_id, objective_index, objective_progress[mission_id][objective_index])
    mission_progress_changed.emit()
    
    if objective_progress[mission_id][objective_index] >= target_count:
        _check_mission_complete(mission_id)

func _check_mission_complete(mission_id: String) -> void:
    var mission = all_missions[mission_id] as MissionData
    var all_done = true
    for i in mission.objectives.size():
        var target = mission.objectives[i].get("count", 1)
        if objective_progress[mission_id][i] < target:
            all_done = false
            break
    
    if all_done:
        complete_mission(mission_id)

func complete_mission(mission_id: String) -> void:
    if mission_id not in active_missions: return
    active_missions.erase(mission_id)
    completed_missions.append(mission_id)
    objective_progress.erase(mission_id)
    
    var mission = all_missions[mission_id] as MissionData
    _grant_rewards(mission)
    mission_completed.emit(mission_id)
    mission_progress_changed.emit()
    PhoneSystem.add_notification("Missions", "Completed!", mission.mission_name)

func fail_mission(mission_id: String) -> void:
    if mission_id not in active_missions: return
    active_missions.erase(mission_id)
    failed_missions.append(mission_id)
    objective_progress.erase(mission_id)
    mission_failed.emit(mission_id)
    mission_progress_changed.emit()
    PhoneSystem.add_notification("Missions", "Failed", 
        all_missions[mission_id].mission_name)

func _grant_rewards(mission: MissionData) -> void:
    var rewards = mission.rewards
    if rewards.has("money") and rewards["money"] > 0:
        MoneySystem.receive_bank_payment(rewards["money"], "Mission: " + mission.mission_name)
    if rewards.has("xp") and rewards["xp"] > 0:
        PlayerStats.add_xp(rewards["xp"])
    if rewards.has("skill_xp"):
        for skill in rewards["skill_xp"]:
            PlayerStats.add_skill_xp(skill, rewards["skill_xp"][skill])
    if rewards.has("items"):
        for item_id in rewards["items"]:
            var item = ItemDatabase.get_item(item_id)
            if item:
                InventorySystem.add_item(item)

func get_available_missions() -> Array[String]:
    var available: Array[String] = []
    for mission_id in all_missions:
        if mission_id in active_missions: continue
        if mission_id in completed_missions: continue
        if mission_id in failed_missions: continue
        var mission = all_missions[mission_id] as MissionData
        var prereqs_met = true
        for prereq in mission.prerequisites:
            if prereq not in completed_missions:
                prereqs_met = false
                break
        if prereqs_met:
            available.append(mission_id)
    return available

func get_mission_progress(mission_id: String) -> Dictionary:
    if not objective_progress.has(mission_id): return {}
    var mission = all_missions[mission_id] as MissionData
    var objectives = []
    for i in mission.objectives.size():
        objectives.append({
            "description": mission.objectives[i].get("description", ""),
            "current": objective_progress[mission_id][i],
            "target": mission.objectives[i].get("count", 1),
            "complete": objective_progress[mission_id][i] >= mission.objectives[i].get("count", 1),
        })
    return {"objectives": objectives, "time_limit": mission.time_limit}
```

---

## Step 4 — Mission Giver NPCs

NPCs that offer missions have a distinct marker above their head.

### `MissionGiver.gd`

```gdscript
extends NPCBase
class_name MissionGiver

@export var offered_missions: Array[String] = []
@onready var mission_marker: Sprite3D = $MissionMarker

func _ready() -> void:
    super._ready()
    _update_marker()
    MissionManager.mission_completed.connect(_on_mission_completed)

func _update_marker() -> void:
    var has_available = false
    for mission_id in offered_missions:
        if MissionManager.get_available_missions().has(mission_id):
            has_available = true
            break
    mission_marker.visible = has_available

func _on_mission_completed(_mission_id: String) -> void:
    _update_marker()

func interact(player: Node3D) -> void:
    var available = []
    for mission_id in offered_missions:
        if MissionManager.get_available_missions().has(mission_id):
            available.append(mission_id)
    if available.size() > 0:
        ShopUIManager.open_mission_dialog(available)
```

---

## Step 5 — Story Arcs

The main story is divided into chapters, each with multiple missions.

### Story Arc: "The Nova City Conspiracy"

| Chapter | Mission | Type | Summary |
| :--- | :--- | :--- | :--- |
| **1** | New Beginnings | Story | Arrive in Nova City, find work, rent an apartment |
| **2** | First Impressions | Fetch | Help a neighbor, earn first contact |
| **3** | The Delivery | Delivery | Deliver a suspicious package, meet a mysterious NPC |
| **4** | Missing Person | Investigation | Investigate a disappearance, find clues |
| **5** | The Warehouse | Stealth | Sneak into a warehouse, discover evidence |
| **6** | Confrontation | Combat | Face the antagonist's henchmen |
| **7** | The Truth | Story | Uncover the conspiracy, make a choice |
| **8** | Resolution | Story | Final mission, branching ending based on choices |

### `StoryManager.gd`

```gdscript
extends Node

signal story_event_triggered(event_id: String)
signal chapter_started(chapter: int)

var story_flags: Dictionary = {}  # flag_name -> value
var current_chapter: int = 1
var story_choices: Dictionary = {}  # choice_id -> selected_option

func set_flag(flag: String, value: Variant = true) -> void:
    story_flags[flag] = value
    story_event_triggered.emit(flag)

func get_flag(flag: String) -> Variant:
    return story_flags.get(flag, false)

func make_choice(choice_id: String, option: int) -> void:
    story_choices[choice_id] = option
    set_flag(choice_id + "_chosen", option)

func get_choice(choice_id: String) -> int:
    return story_choices.get(choice_id, -1)

func advance_chapter() -> void:
    current_chapter += 1
    chapter_started.emit(current_chapter)
    PhoneSystem.add_notification("Story", "Chapter %d" % current_chapter,
        "A new chapter begins...")
```

---

## Step 6 — Mission Tracker App

### `MissionsApp.gd`

```gdscript
extends Control

@onready var active_list: ItemList = $ActiveList
@onready var available_list: ItemList = $AvailableList
@onready var details_panel: RichTextLabel = $DetailsPanel

func on_opened() -> void:
    _refresh_lists()

func _refresh_lists() -> void:
    active_list.clear()
    for mission_id in MissionManager.active_missions:
        var mission = MissionManager.all_missions[mission_id] as MissionData
        active_list.add_item(mission.mission_name)
        active_list.set_item_metadata(active_list.item_count - 1, mission_id)
    
    available_list.clear()
    for mission_id in MissionManager.get_available_missions():
        var mission = MissionManager.all_missions[mission_id] as MissionData
        available_list.add_item(mission.mission_name)
        available_list.set_item_metadata(available_list.item_count - 1, mission_id)

func _on_active_selected(index: int) -> void:
    var mission_id = active_list.get_item_metadata(index)
    var mission = MissionManager.all_missions[mission_id] as MissionData
    var progress = MissionManager.get_mission_progress(mission_id)
    var text = "[b]%s[/b]\n%s\n\n" % [mission.mission_name, mission.description]
    text += "[b]Objectives:[/b]\n"
    for obj in progress["objectives"]:
        var status = "✓" if obj["complete"] else "○"
        text += "%s %s (%d/%d)\n" % [status, obj["description"], obj["current"], obj["target"]]
    text += "\n[b]Rewards:[/b]\n"
    if mission.rewards["money"] > 0:
        text += "• %d Cr\n" % mission.rewards["money"]
    if mission.rewards["xp"] > 0:
        text += "• %d XP\n" % mission.rewards["xp"]
    details_panel.text = text

func _on_available_selected(index: int) -> void:
    var mission_id = available_list.get_item_metadata(index)
    var mission = MissionManager.all_missions[mission_id] as MissionData
    var text = "[b]%s[/b]\n%s\n\n[b]Rewards:[/b]\n" % [mission.mission_name, mission.description]
    if mission.rewards["money"] > 0:
        text += "• %d Cr\n" % mission.rewards["money"]
    details_panel.text = text
```

The mission system provides structured goals that guide the player through the game's content while rewarding exploration and skill development.
