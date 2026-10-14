# Stage 4.11 — Combat System

Combat adds tension and consequence to the game. It includes melee, weapons, a wanted system, and police response.

---

## Goal
Create a combat system with melee fighting, weapons, a wanted level system, and law enforcement response.

---

## Step 1 — Combat Design Philosophy

Combat is not the primary focus of Project Earth, but it exists for narrative tension and player agency. The system emphasizes:
- **Consequences over power fantasy** — violence has real repercussions
- **Melee-first** — guns are rare and expensive
- **Defense matters** — blocking and dodging are essential
- **Police response** — crime is punished

---

## Step 2 — Melee Combat

### Melee Moves

| Move | Input | Stamina Cost | Damage | Effect |
| :--- | :--- | :--- | :--- | :--- |
| **Light Punch** | Left Click | 5 | 5 | Fast, low knockback |
| **Heavy Punch** | Right Click | 15 | 12 | Slow, high knockback |
| **Kick** | F | 10 | 8 | Pushes enemy back |
| **Block** | Right Click (hold) | 2/s | 0 | Reduces incoming damage 70% |
| **Dodge** | Shift + Direction | 8 | 0 | i-frames for 0.3s |
| **Grab** | E | 12 | 3 | Sets up throw |
| **Throw** | E (after grab) | 5 | 10 | Throws enemy, knockdown |

### `MeleeCombat.gd`

```gdscript
extends Node
class_name MeleeCombat

enum State { IDLE, LIGHT_ATTACK, HEAVY_ATTACK, BLOCK, DODGE, GRAB, STAGGERED, KNOCKED_DOWN }

var current_state: State = State.IDLE
var state_timer: float = 0.0
var combo_count: int = 0
var combo_window: float = 1.0
var last_attack_time: float = 0.0

const MOVE_DATA = {
    State.LIGHT_ATTACK: {"duration": 0.3, "damage": 5, "stamina": 5, "knockback": 2.0},
    State.HEAVY_ATTACK: {"duration": 0.6, "damage": 12, "stamina": 15, "knockback": 5.0},
    State.BLOCK: {"duration": 0.0, "damage": 0, "stamina": 2, "knockback": 0.0},
    State.DODGE: {"duration": 0.3, "damage": 0, "stamina": 8, "knockback": 0.0},
    State.GRAB: {"duration": 0.4, "damage": 3, "stamina": 12, "knockback": 0.0},
}

func _physics_process(delta: float) -> void:
    if current_state != State.IDLE:
        state_timer -= delta
        if state_timer <= 0:
            _return_to_idle()

func light_attack() -> void:
    if not _can_attack(): return
    _enter_state(State.LIGHT_ATTACK)
    _deal_damage_in_front(MOVE_DATA[State.LIGHT_ATTACK])
    combo_count += 1
    last_attack_time = Time.get_ticks_msec() / 1000.0

func heavy_attack() -> void:
    if not _can_attack(): return
    _enter_state(State.HEAVY_ATTACK)
    _deal_damage_in_front(MOVE_DATA[State.HEAVY_ATTACK])

func block() -> void:
    if PlayerStats.stats["stamina"] < MOVE_DATA[State.BLOCK]["stamina"]: return
    current_state = State.BLOCK

func stop_block() -> void:
    if current_state == State.BLOCK:
        current_state = State.IDLE

func dodge(direction: Vector3) -> void:
    if not _can_attack(): return
    if PlayerStats.stats["stamina"] < MOVE_DATA[State.DODGE]["stamina"]: return
    _enter_state(State.DODGE)
    # Apply dodge velocity
    var player = get_parent()
    player.velocity = direction * 8.0

func _can_attack() -> bool:
    if current_state == State.STAGGERED or current_state == State.KNOCKED_DOWN:
        return false
    var move = MOVE_DATA.get(current_state, {})
    if PlayerStats.stats["stamina"] < move.get("stamina", 0):
        return false
    return true

func _enter_state(state: State) -> void:
    current_state = state
    state_timer = MOVE_DATA.get(state, {}).get("duration", 0.0)
    var stamina_cost = MOVE_DATA.get(state, {}).get("stamina", 0)
    PlayerStats._modify_stat("stamina", -stamina_cost)

func _deal_damage_in_front(move_data: Dictionary) -> void:
    var player = get_parent()
    var space = player.get_world_3d().direct_space_state
    var from = player.global_position + Vector3.UP * 1.0
    var to = from - player.global_transform.basis.z * 2.0
    var query = PhysicsRayQueryParameters3D.create(from, to)
    var result = space.intersect_ray(query)
    if result:
        var target = result["collider"]
        if target.has_method("take_damage"):
            target.take_damage(move_data["damage"], player.global_position, move_data["knockback"])

func _return_to_idle() -> void:
    current_state = State.IDLE
    # Reset combo if window expired
    if Time.get_ticks_msec() / 1000.0 - last_attack_time > combo_window:
        combo_count = 0

func take_hit(damage: float, from_position: Vector3) -> void:
    if current_state == State.BLOCK:
        damage *= 0.3
    elif current_state == State.DODGE:
        return  # i-frames
    
    PlayerStats._modify_stat("health", -damage)
    _enter_state(State.STAGGERED)
    state_timer = 0.3
    
    if PlayerStats.stats["health"] <= 0:
        DeathSystem._on_player_death()
```

---

## Step 3 — Weapons System

### Weapon Types

| Weapon | Type | Damage | Range | Fire Rate | Price | Legality |
| :--- | :--- | :--- | :--- | :--- | :--- | :--- |
| **Fists** | Melee | 5 | 2m | Fast | Free | Legal |
| **Baseball Bat** | Melee | 10 | 2m | Medium | 50 Cr | Legal |
| **Knife** | Melee | 15 | 1.5m | Fast | 100 Cr | Legal |
| **Stun Gun** | Ranged | 5 | 5m | Slow | 300 Cr | Legal |
| **Pistol** | Ranged | 25 | 50m | Medium | 1,000 Cr | Restricted |
| **Shotgun** | Ranged | 40 | 20m | Slow | 2,500 Cr | Restricted |

### `WeaponData.gd`

```gdscript
extends Resource
class_name WeaponData

@export var weapon_id: String = ""
@export var display_name: String = ""
@export var weapon_type: String = "melee"  # melee, ranged
@export var damage: float = 5.0
@export var range: float = 2.0
@export var fire_rate: float = 0.5  # seconds between attacks
@export var magazine_size: int = 0  # 0 = melee, no ammo
@export var reload_time: float = 0.0
@export var price: int = 0
@export var legality: String = "legal"  # legal, restricted, illegal
@export var scene: PackedScene
@export var icon: Texture2D
```

### `WeaponController.gd`

```gdscript
extends Node3D
class_name WeaponController

@export var equipped_weapon: WeaponData = null
var ammo_in_magazine: int = 0
var last_fire_time: float = 0.0

func equip(weapon: WeaponData) -> void:
    equipped_weapon = weapon
    if weapon.magazine_size > 0:
        ammo_in_magazine = weapon.magazine_size

func attack(target_position: Vector3 = Vector3.ZERO) -> void:
    if equipped_weapon == null: return
    var now = Time.get_ticks_msec() / 1000.0
    if now - last_fire_time < equipped_weapon.fire_rate: return
    
    last_fire_time = now
    
    if equipped_weapon.weapon_type == "melee":
        _melee_attack()
    else:
        _ranged_attack(target_position)

func _melee_attack() -> void:
    var player = get_parent()
    var space = player.get_world_3d().direct_space_state
    var from = player.global_position + Vector3.UP * 1.0
    var to = from - player.global_transform.basis.z * equipped_weapon.range
    var query = PhysicsRayQueryParameters3D.create(from, to)
    var result = space.intersect_ray(query)
    if result:
        var target = result["collider"]
        if target.has_method("take_damage"):
            target.take_damage(equipped_weapon.damage, player.global_position, 3.0)

func _ranged_attack(target_position: Vector3) -> void:
    if ammo_in_magazine <= 0:
        _reload()
        return
    
    ammo_in_magazine -= 1
    var player = get_parent()
    var space = player.get_world_3d().direct_space_state
    var from = global_position
    var to = target_position if target_position != Vector3.ZERO else from - player.global_transform.basis.z * equipped_weapon.range
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [player]
    var result = space.intersect_ray(query)
    if result:
        var target = result["collider"]
        if target.has_method("take_damage"):
            target.take_damage(equipped_weapon.damage, from, 2.0)
    
    # Alert nearby NPCs
    _alert_nearby_npcs()

func _reload() -> void:
    if equipped_weapon.magazine_size == 0: return
    # Check inventory for ammo
    # For now, instant reload
    ammo_in_magazine = equipped_weapon.magazine_size

func _alert_nearby_npcs() -> void:
    var player = get_parent()
    var npcs = get_tree().get_nodes_in_group("npc")
    for npc in npcs:
        if npc.global_position.distance_to(player.global_position) < 15.0:
            if npc.has_method("_on_heard_gunshot"):
                npc._on_heard_gunshot(player.global_position)
```

---

## Step 4 — Wanted System

### `WantedSystem.gd` (Autoload)

```gdscript
extends Node

signal wanted_level_changed(level: int)

var wanted_level: int = 0  # 0-5 stars
var wanted_decay_timer: float = 0.0
var last_crime_time: float = 0.0
var crimes_committed: Array[Dictionary] = []

const WANTED_THRESHOLDS = [0, 10, 25, 50, 75, 100]  # Crime points for each star

func add_crime(crime_type: String, severity: float) -> void:
    var crime_points = _get_crime_points(crime_type, severity)
    crimes_committed.append({
        "type": crime_type,
        "severity": severity,
        "points": crime_points,
        "time": TimeSystem.get_day(),
    })
    last_crime_time = Time.get_ticks_msec() / 1000.0
    _recalculate_wanted_level()

func _get_crime_points(crime_type: String, severity: float) -> float:
    match crime_type:
        "assault": return 10.0 * severity
        "theft": return 5.0 * severity
        "vandalism": return 3.0 * severity
        "armed_robbery": return 20.0 * severity
        "murder": return 50.0 * severity
        "resisting_arrest": return 15.0 * severity
        "gun_in_public": return 8.0 * severity
        _: return 5.0 * severity

func _recalculate_wanted_level() -> void:
    var total_points = 0.0
    for crime in crimes_committed:
        total_points += crime["points"]
    
    var new_level = 0
    for i in range(WANTED_THRESHOLDS.size() - 1, -1, -1):
        if total_points >= WANTED_THRESHOLDS[i]:
            new_level = i
            break
    
    if new_level != wanted_level:
        wanted_level = new_level
        wanted_level_changed.emit(wanted_level)
        if wanted_level > 0:
            PhoneSystem.add_notification("Police", "Wanted Level",
                "%d star(s)" % wanted_level)

func _process(delta: float) -> void:
    if wanted_level == 0: return
    # Decay wanted level over time if no new crimes
    var time_since_crime = Time.get_ticks_msec() / 1000.0 - last_crime_time
    if time_since_crime > 30.0:  # 30 seconds without crime
        wanted_decay_timer += delta
        if wanted_decay_timer > 10.0:  # Reduce every 10 seconds
            wanted_decay_timer = 0.0
            _reduce_wanted_level()

func _reduce_wanted_level() -> void:
    # Remove oldest crime
    if crimes_committed.size() > 0:
        crimes_committed.pop_front()
    _recalculate_wanted_level()

func clear_wanted() -> void:
    wanted_level = 0
    crimes_committed.clear()
    wanted_level_changed.emit(0)
```

### Wanted Level Effects

| Stars | Response | Police Action |
| :--- | :--- | :--- |
| **1** | Awareness | Patrol cars look for player |
| **2** | Active search | Police approach on sight |
| **3** | Pursuit | Police chase on foot and in cars |
| **4** | Heavy pursuit | Roadblocks, more units |
| **5** | City-wide manhunt | All police units, possible roadblocks |

---

## Step 5 — Police AI

### `PoliceNPC.gd`

```gdscript
extends AdvancedNPC
class_name PoliceNPC

enum PoliceState { PATROL, INVESTIGATE, PURSUE, ARREST, RETURN_TO_POST }

var police_state: PoliceState = PoliceState.PATROL
var patrol_route: Array[Vector3] = []
var patrol_index: int = 0
var investigate_position: Vector3 = Vector3.ZERO
var arrest_target: Node3D = null

func _ready() -> void:
    super._ready()
    WantedSystem.wanted_level_changed.connect(_on_wanted_changed)

func _on_wanted_changed(level: int) -> void:
    if level >= 2 and police_state == PoliceState.PATROL:
        _find_player()

func _find_player() -> void:
    investigate_position = GlobalWorldState.player_global_position
    police_state = PoliceState.INVESTIGATE
    target_position = investigate_position
    _move_to(target_position)

func _on_reached_target() -> void:
    match police_state:
        PoliceState.PATROL:
            patrol_index = (patrol_index + 1) % patrol_route.size()
            target_position = patrol_route[patrol_index]
            _move_to(target_position)
        PoliceState.INVESTIGATE:
            if _can_see_player():
                police_state = PoliceState.PURSUE
            else:
                police_state = PoliceState.RETURN_TO_POST
        PoliceState.PURSUE:
            if _can_see_player():
                if global_position.distance_to(GlobalWorldState.player_global_position) < 2.0:
                    _attempt_arrest()
            else:
                police_state = PoliceState.INVESTIGATE
        PoliceState.RETURN_TO_POST:
            police_state = PoliceState.PATROL
            patrol_index = 0
            target_position = patrol_route[0]
            _move_to(target_position)

func _can_see_player() -> bool:
    var player_pos = GlobalWorldState.player_global_position
    if global_position.distance_to(player_pos) > 30.0: return false
    var space = get_world_3d().direct_space_state
    var from = global_position + Vector3.UP * 1.5
    var to = player_pos + Vector3.UP * 1.0
    var query = PhysicsRayQueryParameters3D.create(from, to)
    query.exclude = [self]
    var result = space.intersect_ray(query)
    if result and result["collider"].is_in_group("player"):
        return true
    return false

func _attempt_arrest() -> void:
    police_state = PoliceState.ARREST
    if WantedSystem.wanted_level <= 3:
        _say("Stop! You're under arrest!")
        ShopUIManager.open_arrest_ui()
    else:
        # Higher wanted = use force
        _say("Take him down!")
        _engage_combat()

func _engage_combat() -> void:
    var player = get_tree().get_first_node_in_group("player")
    if player and player.has_method("take_hit"):
        player.take_hit(5.0, global_position)
```

---

## Step 6 — Arrest & Consequences

### `ArrestSystem.gd`

```gdscript
extends Node

func get_arrested() -> void:
    var fine = WantedSystem.wanted_level * 500
    var jail_time = WantedSystem.wanted_level * 2  # in-game hours
    
    # Pay fine
    if MoneySystem.cash >= fine:
        MoneySystem.spend_cash(fine)
    else:
        # Confiscate items to cover fine
        var remaining = fine - MoneySystem.cash
        MoneySystem.cash = 0
        _confiscate_items(remaining)
    
    # Serve jail time
    TimeSystem.advance_time(jail_time)
    
    # Clear wanted
    WantedSystem.clear_wanted()
    
    # Reputation hit
    ReputationSystem.modify_reputation("police", -5, "arrested")
    
    # Teleport to police station exit
    GlobalWorldState.player_global_position = Vector3(0, 0, -50)
    
    PhoneSystem.add_notification("Police", "Arrested",
        "Fine: %d Cr. Served %d hours." % [fine, jail_time])

func _confiscate_items(value_needed: int) -> void:
    var confiscated_value = 0
    var items = InventorySystem.get_all_items()
    for item in items:
        if confiscated_value >= value_needed: break
        InventorySystem.remove_item(item)
        confiscated_value += item.value
```

The combat system provides meaningful conflict with real consequences, discouraging reckless violence while allowing it as a narrative tool.
