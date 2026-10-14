# Stage 4.10 — Advanced NPC AI

Advanced NPC AI brings the city to life. NPCs have schedules, relationships, memories, and react to the player's actions.

---

## Goal
Create a deep NPC AI system with daily routines, relationship tracking, dialogue, memory, and a reputation system.

---

## Step 1 — NPC Schedule System

Each NPC follows a daily schedule based on the time of day.

### `NPCSchedule.gd`

```gdscript
extends Resource
class_name NPCSchedule

@export var schedule_entries: Array[Dictionary] = []
# Each entry: {hour, activity, location, duration}

func get_activity_at_hour(hour: float) -> Dictionary:
    for entry in schedule_entries:
        var start = entry["hour"]
        var end = start + entry.get("duration", 2.0)
        if hour >= start and hour < end:
            return entry
    return {"activity": "idle", "location": "home", "duration": 1.0}
```

### Typical NPC Schedule

| Time | Activity | Location |
| :--- | :--- | :--- |
| 06:00–07:00 | Wake up, breakfast | Home |
| 07:00–08:00 | Commute | Walking/Driving |
| 08:00–12:00 | Work | Workplace |
| 12:00–13:00 | Lunch break | Restaurant/Park |
| 13:00–17:00 | Work | Workplace |
| 17:00–18:00 | Commute | Walking/Driving |
| 18:00–19:00 | Dinner | Home/Restaurant |
| 19:00–22:00 | Free time | Park/Bar/Home |
| 22:00–06:00 | Sleep | Home |

---

## Step 2 — NPC Personality

### `NPCPersonality.gd`

```gdscript
extends Resource
class_name NPCPersonality

enum Trait { FRIENDLY, AGGRESSIVE, SHY, LAZY, HARDWORKING, CURIOUS, GREEDY, GENEROUS }

@export var traits: Array[Trait] = []
@export var friendliness: float = 0.5  # 0-1
@export var aggression: float = 0.2  # 0-1
@export var bravery: float = 0.5  # 0-1
@export var intelligence: float = 0.5  # 0-1
@export var humor: float = 0.5  # 0-1
@export var daily_routine: NPCSchedule

func get_reaction_to_action(action: String) -> float:
    match action:
        "greeting":
            return friendliness
        "insult":
            return -aggression
        "gift":
            return friendliness + (0.3 if Trait.GREEDY in traits else 0.0)
        "threat":
            return -bravery
        "joke":
            return humor
        _:
            return 0.0
```

---

## Step 3 — Relationship System

### `RelationshipSystem.gd` (Autoload)

```gdscript
extends Node

signal relationship_changed(npc_id: String, new_value: float)

var relationships: Dictionary = {}  # npc_id -> {value, history, last_interaction}

const RELATIONSHIP_LEVELS = {
    -100: "Hostile",
    -50: "Disliked",
    -10: "Unfriendly",
    0: "Neutral",
    10: "Acquaintance",
    30: "Friendly",
    60: "Close Friend",
    80: "Best Friend",
    90: "Romantic Partner",
}

func get_relationship(npc_id: String) -> float:
    if not relationships.has(npc_id): return 0.0
    return relationships[npc_id]["value"]

func get_relationship_level(npc_id: String) -> String:
    var value = get_relationship(npc_id)
    var level = "Neutral"
    for threshold in RELATIONSHIP_LEVELS.keys():
        if value >= threshold:
            level = RELATIONSHIP_LEVELS[threshold]
    return level

func modify_relationship(npc_id: String, amount: float, reason: String = "") -> void:
    if not relationships.has(npc_id):
        relationships[npc_id] = {"value": 0.0, "history": [], "last_interaction": 0}
    
    relationships[npc_id]["value"] = clamp(
        relationships[npc_id]["value"] + amount, -100.0, 100.0)
    relationships[npc_id]["last_interaction"] = TimeSystem.get_day()
    relationships[npc_id]["history"].append({
        "day": TimeSystem.get_day(),
        "amount": amount,
        "reason": reason,
    })
    
    relationship_changed.emit(npc_id, relationships[npc_id]["value"])

func decay_relationships() -> void:
    # Called daily — relationships slowly drift toward neutral
    for npc_id in relationships:
        var value = relationships[npc_id]["value"]
        if value > 0:
            relationships[npc_id]["value"] = max(0, value - 0.5)
        elif value < 0:
            relationships[npc_id]["value"] = min(0, value + 0.5)
```

### Relationship Modifiers

| Action | Effect | Notes |
| :--- | :--- | :--- |
| **Greeting** | +1 | Small, once per day per NPC |
| **Gift (liked)** | +5 to +15 | Depends on NPC preferences |
| **Gift (disliked)** | -5 | Wrong gift hurts |
| **Help with task** | +10 | Quest-related |
| **Complete mission** | +15 to +25 | Story missions give more |
| **Insult** | -10 | Verbal |
| **Attack** | -30 | Combat |
| **Kill friend** | -50 | Severe |
| **Save from danger** | +30 | Heroic act |

---

## Step 4 — NPC Memory

NPCs remember events and reference them in dialogue.

### `NPCMemory.gd`

```gdscript
extends Resource
class_name NPCMemory

@export var memories: Array[Dictionary] = []
# Each memory: {event, timestamp, importance, emotional_weight}

func add_memory(event: String, importance: float = 0.5, emotional_weight: float = 0.0) -> void:
    memories.append({
        "event": event,
        "timestamp": TimeSystem.get_day(),
        "importance": importance,
        "emotional_weight": emotional_weight,
    })
    # Keep only the most important 20 memories
    if memories.size() > 20:
        memories.sort_custom(func(a, b): return a["importance"] > b["importance"])
        memories = memories.slice(0, 20)

func get_relevant_memories(topic: String) -> Array:
    var relevant = []
    for memory in memories:
        if topic.to_lower() in memory["event"].to_lower():
            relevant.append(memory)
    return relevant

func has_memory(event: String) -> bool:
    for memory in memories:
        if memory["event"] == event:
            return true
    return false
```

---

## Step 5 — Dialogue System

### `DialogueData.gd`

```gdscript
extends Resource
class_name DialogueData

@export var dialogue_id: String = ""
@export var npc_id: String = ""
@export var nodes: Array[Dictionary] = []
# Each node: {id, text, responses: [{text, next_node, conditions, effects}]}

func get_node(node_id: String) -> Dictionary:
    for node in nodes:
        if node["id"] == node_id:
            return node
    return {}

func get_starting_node() -> Dictionary:
    return get_node("start")
```

### `DialogueManager.gd`

```gdscript
extends Node

var dialogues: Dictionary = {}  # dialogue_id -> DialogueData
var current_dialogue: DialogueData = null
var current_node: Dictionary = {}

func start_dialogue(dialogue_id: String) -> void:
    if not dialogues.has(dialogue_id): return
    current_dialogue = dialogues[dialogue_id]
    current_node = current_dialogue.get_starting_node()
    ShopUIManager.open_dialogue_ui(current_node)

func select_response(response_index: int) -> void:
    if current_node.is_empty(): return
    var responses = current_node.get("responses", [])
    if response_index >= responses.size(): return
    
    var response = responses[response_index]
    
    # Check conditions
    if not _check_conditions(response.get("conditions", {})):
        return
    
    # Apply effects
    _apply_effects(response.get("effects", {}))
    
    # Move to next node
    var next_id = response.get("next_node", "")
    if next_id == "end":
        end_dialogue()
    else:
        current_node = current_dialogue.get_node(next_id)
        ShopUIManager.update_dialogue_ui(current_node)

func _check_conditions(conditions: Dictionary) -> bool:
    for key in conditions:
        match key:
            "min_relationship":
                if RelationshipSystem.get_relationship(current_dialogue.npc_id) < conditions[key]:
                    return false
            "story_flag":
                if not StoryManager.get_flag(conditions[key]):
                    return false
            "has_item":
                if not InventorySystem.has_item(conditions[key]):
                    return false
    return true

func _apply_effects(effects: Dictionary) -> void:
    for key in effects:
        match key:
            "relationship":
                RelationshipSystem.modify_relationship(
                    current_dialogue.npc_id, effects[key], "dialogue")
            "story_flag":
                StoryManager.set_flag(effects[key])
            "give_item":
                var item = ItemDatabase.get_item(effects[key])
                if item:
                    InventorySystem.add_item(item)
            "money":
                if effects[key] > 0:
                    MoneySystem.add_cash(effects[key])
                else:
                    MoneySystem.spend_cash(abs(effects[key]))

func end_dialogue() -> void:
    current_dialogue = null
    current_node = {}
    ShopUIManager.close_dialogue_ui()
```

---

## Step 6 — Reputation System

The player's reputation affects how NPCs and factions react.

### `ReputationSystem.gd` (Autoload)

```gdscript
extends Node

signal reputation_changed(faction: String, new_value: float)

var faction_reputation: Dictionary = {}  # faction -> float (-100 to 100)

const FACTIONS = {
    "police": "Police Department",
    "medical": "Medical Staff",
    "business": "Business Owners",
    "criminals": "Underground",
    "citizens": "General Citizens",
    "media": "Media Outlets",
}

func get_reputation(faction: String) -> float:
    return faction_reputation.get(faction, 0.0)

func modify_reputation(faction: String, amount: float, reason: String = "") -> void:
    var current = get_reputation(faction)
    faction_reputation[faction] = clamp(current + amount, -100.0, 100.0)
    reputation_changed.emit(faction, faction_reputation[faction])
    
    var level = get_reputation_level(faction)
    PhoneSystem.add_notification("Reputation", FACTIONS[faction],
        "%s (%.0f)" % [level, faction_reputation[faction]])

func get_reputation_level(faction: String) -> String:
    var value = get_reputation(faction)
    if value >= 75: return "Heroic"
    if value >= 50: return "Respected"
    if value >= 25: return "Liked"
    if value >= 10: return "Friendly"
    if value > -10: return "Neutral"
    if value > -25: return "Disliked"
    if value > -50: return "Wanted"
    if value > -75: return "Hated"
    return "Villain"

func get_reaction_modifier(faction: String) -> float:
    # Returns a multiplier for NPC friendliness
    var value = get_reputation(faction)
    return 1.0 + (value / 100.0)
```

### Reputation Modifiers

| Action | Faction | Change |
| :--- | :--- | :--- |
| **Complete mission for faction** | That faction | +10 |
| **Help faction member** | That faction | +5 |
| **Attack faction member** | That faction | -15 |
| **Kill faction member** | That faction | -40 |
| **Donate to charity** | Citizens | +5 |
| **Commit crime** | Police | -20, Criminals +5 |
| **Solve crime** | Police | +15 |
| **Save NPC** | Citizens | +10 |

---

## Step 7 — Advanced NPC Controller

### `AdvancedNPC.gd`

```gdscript
extends NPCBase
class_name AdvancedNPC

@export var npc_id: String = ""
@export var personality: NPCPersonality
@export var memory: NPCMemory
@export var home_location: Vector3 = Vector3.ZERO
@export var work_location: Vector3 = Vector3.ZERO

var current_activity: String = "idle"
var target_position: Vector3 = Vector3.ZERO
var dialogue_id: String = ""

func _ready() -> void:
    super._ready()
    TimeSystem.hour_changed.connect(_on_hour_changed)
    _on_hour_changed(TimeSystem.get_hour())

func _on_hour_changed(hour: float) -> void:
    if personality == null or personality.daily_routine == null: return
    var activity = personality.daily_routine.get_activity_at_hour(hour)
    current_activity = activity["activity"]
    
    match activity["location"]:
        "home":
            target_position = home_location
        "work":
            target_position = work_location
        "restaurant":
            target_position = _find_nearest("restaurant")
        "park":
            target_position = _find_nearest("park")
        "bar":
            target_position = _find_nearest("bar")
    
    _move_to(target_position)

func _find_nearest(type: String) -> Vector3:
    return GlobalWorldState.find_nearest_location(global_position, type)

func interact(player: Node3D) -> void:
    var relationship = RelationshipSystem.get_relationship(npc_id)
    var reaction = personality.get_reaction_to_action("greeting")
    var rep_mod = ReputationSystem.get_reaction_modifier("citizens")
    
    if relationship + (reaction * rep_mod * 10) > -10:
        DialogueManager.start_dialogue(dialogue_id)
    else:
        _say("I don't want to talk to you.")

func _say(text: String) -> void:
        HUDManager.show_subtitle(npc_id, text)

func _on_attacked(attacker: Node3D) -> void:
    RelationshipSystem.modify_relationship(npc_id, -30, "attacked")
    ReputationSystem.modify_reputation("citizens", -5, "attacked civilian")
    memory.add_memory("Was attacked by player", 0.9, -0.8)
    
    if personality.bravery > 0.5:
        _flee()
    else:
        _call_police()

func _flee() -> void:
    var away_dir = (global_position - GlobalWorldState.player_global_position).normalized()
    target_position = global_position + away_dir * 20.0
    _move_to(target_position)

func _call_police() -> void:
    ReputationSystem.modify_reputation("police", -10, "assault reported")
    PhoneSystem.add_notification("Police", "Reported",
        "A civilian reported you to the police.")
```

The advanced NPC AI system creates a living, breathing city where every character has a life, remembers the player's actions, and reacts accordingly.
