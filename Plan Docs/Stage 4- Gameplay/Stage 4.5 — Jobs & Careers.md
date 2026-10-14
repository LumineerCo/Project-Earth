# Stage 4.5 — Jobs & Careers

Jobs provide the primary income source for the player. They range from simple repetitive tasks to complex career paths with promotions and salary increases.

---

## Goal
Create a job system with multiple job types, work mini-games, promotion tracks, and scheduled work hours.

---

## Step 1 — Job Types

| Job | Location | Base Pay (Cr/hr) | Schedule | Skill Required |
| :--- | :--- | :--- | :--- | :--- |
| **Delivery Driver** | Industrial Port | 25 | Flexible | Driving 5+ |
| **Taxi Driver** | Central Plaza | 30 | Flexible | Driving 10+ |
| **Barista** | Financial District | 18 | 6am–2pm | Cooking 1+ |
| **Chef** | Coastal Marina | 35 | 11am–9pm | Cooking 20+ |
| **Store Clerk** | Suburban Mall | 15 | 9am–5pm | Charisma 1+ |
| **Office Worker** | Financial District | 45 | 9am–5pm | Intelligence 10+ |
| **Mechanic** | Highway Garage | 30 | 8am–6pm | Crafting 10+ |
| **Security Guard** | Industrial Port | 22 | Night shift | Strength 10+ |
| **Fisherman** | Coastal Marina | 28 | 4am–10am | Fitness 5+ |
| **Garbage Collector** | City-wide | 20 | 5am–1pm | Fitness 5+ |

---

## Step 2 — Career Progression

Each job has a promotion track with 5 levels.

| Level | Title | Pay Multiplier | Requirement |
| :--- | :--- | :--- | :--- |
| **1** | Trainee | 1.0x | Hire |
| **2** | Junior | 1.3x | 10 shifts worked |
| **3** | Senior | 1.6x | 25 shifts + skill 20 |
| **4** | Manager | 2.0x | 50 shifts + skill 40 |
| **5** | Expert | 2.5x | 100 shifts + skill 60 |

---

## Step 3 — Job Data Model

### `JobData.gd`

```gdscript
extends Resource
class_name JobData

@export var job_id: String = ""
@export var job_name: String = ""
@export var description: String = ""
@export var location: String = ""  # District name
@export var base_pay: int = 20  # Credits per hour
@export var required_skill: String = ""
@export var required_skill_level: int = 0
@export var start_hour: int = 9
@export var end_hour: int = 17
@export var flexible_hours: bool = false
@export var minigame_scene: PackedScene
@export var promotion_track: Array[String] = ["Trainee", "Junior", "Senior", "Manager", "Expert"]
```

---

## Step 4 — Job Manager

### `JobManager.gd` (Autoload)

```gdscript
extends Node

signal job_started(job_id: String)
signal job_ended(job_id: String, earnings: int)
signal promotion_earned(job_id: String, new_level: int, new_title: String)
signal shift_started
signal shift_ended

var available_jobs: Dictionary = {}  # job_id -> JobData
var current_job: String = ""
var job_level: Dictionary = {}  # job_id -> level (1-5)
var shifts_worked: Dictionary = {}  # job_id -> count
var is_working: bool = false
var shift_start_time: float = 0.0

func _ready() -> void:
    _load_jobs()

func _load_jobs() -> void:
    var dir = DirAccess.open("res://data/jobs")
    if dir:
        dir.list_dir_begin()
        var file = dir.get_next()
        while file != "":
            if file.ends_with(".tres"):
                var job = load(dir.get_current_dir() + "/" + file) as JobData
                if job:
                    available_jobs[job.job_id] = job
                    job_level[job.job_id] = 1
                    shifts_worked[job.job_id] = 0
            file = dir.get_next()

func apply_for_job(job_id: String) -> bool:
    if not available_jobs.has(job_id): return false
    var job = available_jobs[job_id] as JobData
    if PlayerStats.skills[job.required_skill] < job.required_skill_level:
        PhoneSystem.add_notification("Jobs", "Application Rejected", 
            "Requires %s level %d" % [job.required_skill.capitalize(), job.required_skill_level])
        return false
    current_job = job_id
    if not job_level.has(job_id):
        job_level[job_id] = 1
        shifts_worked[job_id] = 0
    PhoneSystem.add_notification("Jobs", "Hired!", 
        "You got the job: %s" % job.job_name)
    return true

func start_shift() -> void:
    if current_job == "": return
    var job = available_jobs[current_job] as JobData
    var hour = TimeSystem.current_hour
    
    if not job.flexible_hours:
        if hour < job.start_hour or hour >= job.end_hour:
            PhoneSystem.add_notification("Jobs", "Not Work Hours",
                "Your shift is %d:00–%d:00" % [job.start_hour, job.end_hour])
            return
    
    is_working = true
    shift_start_time = Time.get_ticks_msec() / 1000.0
    shift_started.emit()
    job_started.emit(current_job)
    
    # Launch mini-game
    if job.minigame_scene:
        var minigame = job.minigame_scene.instantiate()
        get_tree().current_scene.add_child(minigame)
        minigame.shift_completed.connect(_on_shift_completed)

func end_shift() -> void:
    if not is_working: return
    is_working = false
    var elapsed = (Time.get_ticks_msec() / 1000.0) - shift_start_time
    var hours_worked = elapsed / 3600.0  # Real-time to game-time conversion
    # For gameplay, use game time
    hours_worked = max(1.0, hours_worked)
    
    var job = available_jobs[current_job] as JobData
    var level = job_level[current_job]
    var pay_multiplier = 1.0 + (level - 1) * 0.3
    var earnings = int(job.base_pay * hours_worked * pay_multiplier)
    
    MoneySystem.receive_bank_payment(earnings, job.job_name)
    shifts_worked[current_job] += 1
    _check_promotion(current_job)
    
    shift_ended.emit()
    job_ended.emit(current_job, earnings)
    
    PhoneSystem.add_notification("Bank", "Paycheck",
        "+%d Cr for %s shift" % [earnings, job.job_name])

func _on_shift_completed(score: float) -> void:
    # Score from mini-game affects pay
    end_shift()

func _check_promotion(job_id: String) -> void:
    var job = available_jobs[job_id] as JobData
    var level = job_level[job_id]
    var shifts = shifts_worked[job_id]
    var skill = PlayerStats.skills[job.required_skill]
    
    var next_level = level + 1
    if next_level > 5: return
    
    var shifts_needed = [0, 10, 25, 50, 100][next_level - 1]
    var skill_needed = [0, 0, 20, 40, 60][next_level - 1]
    
    if shifts >= shifts_needed and skill >= skill_needed:
        job_level[job_id] = next_level
        var new_title = job.promotion_track[next_level - 1]
        promotion_earned.emit(job_id, next_level, new_title)
        PhoneSystem.add_notification("Jobs", "Promotion!",
            "You are now %s at %s" % [new_title, job.job_name])

func quit_job() -> void:
    if current_job == "": return
    var job = available_jobs[current_job] as JobData
    PhoneSystem.add_notification("Jobs", "Resigned",
        "You quit your job as %s" % job.job_name)
    current_job = ""
```

---

## Step 5 — Work Mini-Games

Each job has a mini-game that the player completes during their shift.

### Coffee-Making Mini-Game (Barista)

```gdscript
extends Node2D
class_name BaristaMinigame

signal shift_completed(score: float)

@onready var coffee_machine: Sprite2D = $CoffeeMachine
@onready var progress_bar: ProgressBar = $ProgressBar
@onready var order_label: Label = $OrderLabel

var current_order: Dictionary = {}
var cups_served: int = 0
var cups_target: int = 10
var mistakes: int = 0

func _ready() -> void:
    _generate_order()

func _generate_order() -> void:
    var types = ["Espresso", "Latte", "Cappuccino", "Americano"]
    current_order = {
        "type": types.pick_random(),
        "milk": randi() % 3,  # 0, 1, or 2 shots
        "sugar": randi() % 3,
    }
    order_label.text = "Order: %s | Milk: %d | Sugar: %d" % [
        current_order["type"], current_order["milk"], current_order["sugar"]]

func _on_serve_pressed(milk: int, sugar: int, type: String) -> void:
    if type == current_order["type"] and milk == current_order["milk"] and sugar == current_order["sugar"]:
        cups_served += 1
        progress_bar.value = float(cups_served) / cups_target * 100
        if cups_served >= cups_target:
            var score = 1.0 - (float(mistakes) / cups_target)
            shift_completed.emit(score)
            queue_free()
    else:
        mistakes += 1
    _generate_order()
```

### Delivery Mini-Game (Driver)

```gdscript
extends Node
class_name DeliveryMinigame

signal shift_completed(score: float)

var packages_delivered: int = 0
var packages_target: int = 5
var current_destination: Vector3 = Vector3.ZERO

func _ready() -> void:
    _assign_destination()

func _assign_destination() -> void:
    # Pick random building in Industrial District
    current_destination = DistrictSystem.get_random_point_in_district("Industrial Port")
    HUDManager.set_waypoint(current_destination)

func on_package_delivered() -> void:
    packages_delivered += 1
    PlayerStats.add_skill_xp("driving", 5)
    if packages_delivered >= packages_target:
        shift_completed.emit(1.0)
        queue_free()
    else:
        _assign_destination()
```

---

## Step 6 — Job Locations

Job locations are marked on the map and have interaction zones.

### `JobLocationInteractable.gd`

```gdscript
extends Area3D
class_name JobLocationInteractable

@export var job_id: String = ""

func _ready() -> void:
    body_entered.connect(_on_body_entered)
    body_exited.connect(_on_body_exited)

func _on_body_entered(body: Node3D) -> void:
    if body.is_in_group("Player"):
        var job = JobManager.available_jobs.get(job_id)
        if job:
            HUDManager.show_interaction_prompt("Press E to start work: %s" % job.job_name)
            body.set_nearby_interactable(self)

func _on_body_exited(body: Node3D) -> void:
    if body.is_in_group("Player"):
        HUDManager.hide_interaction_prompt()
        body.clear_nearby_interactable()

func interact(player: Node3D) -> void:
    if JobManager.current_job == job_id:
        JobManager.start_shift()
    elif JobManager.current_job == "":
        ShopUIManager.open_job_application(job_id)
    else:
        JobManager.start_shift()
```

The job system gives players a structured way to earn money, develop skills, and feel progression through promotions.
