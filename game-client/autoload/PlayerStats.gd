## PlayerStats.gd
## Player health, stamina, hunger, thirst, energy, skills, and progression.
## Stage 4.1 — Player Character & Stats
extends Node
class_name PlayerStats

signal stat_changed(stat_name: String, value: float)
signal skill_leveled_up(skill_name: String, new_level: int)
signal player_died

const HUNGER_RATE := 1.0 / 30.0
const THIRST_RATE := 1.0 / 20.0
const ENERGY_RATE := 1.0 / 60.0
const HEALTH_REGEN_RATE := 1.0
const STAMINA_REGEN_RATE := 5.0
const STAMINA_PENALTY_RATE := 2.0

var stats: Dictionary = {
	"health": 100.0,
	"stamina": 100.0,
	"hunger": 100.0,
	"thirst": 100.0,
	"energy": 100.0,
}

var max_stats: Dictionary = {
	"health": 100.0,
	"stamina": 100.0,
	"hunger": 100.0,
	"thirst": 100.0,
	"energy": 100.0,
}

var skills: Dictionary = {
	"driving": 1,
	"fitness": 1,
	"strength": 1,
	"charisma": 1,
	"intelligence": 1,
	"cooking": 1,
	"crafting": 1,
}

var skill_xp: Dictionary = {
	"driving": 0,
	"fitness": 0,
	"strength": 0,
	"charisma": 0,
	"intelligence": 0,
	"cooking": 0,
	"crafting": 0,
}

var level: int = 1
var total_xp: int = 0
var current_xp: int = 0

func _ready() -> void:
	set_process(true)
	reset_to_default()
	DebugManager.log_info("PlayerStats", "Player stats initialized")

func _process(delta: float) -> void:
	_decay_stats(delta)
	_regen_stats(delta)
	_check_death()

func reset_to_default() -> void:
	stats = {
		"health": 100.0,
		"stamina": 100.0,
		"hunger": 100.0,
		"thirst": 100.0,
		"energy": 100.0,
	}
	max_stats = {
		"health": 100.0,
		"stamina": 100.0,
		"hunger": 100.0,
		"thirst": 100.0,
		"energy": 100.0,
	}
	skills = {
		"driving": 1,
		"fitness": 1,
		"strength": 1,
		"charisma": 1,
		"intelligence": 1,
		"cooking": 1,
		"crafting": 1,
	}
	skill_xp = {
		"driving": 0,
		"fitness": 0,
		"strength": 0,
		"charisma": 0,
		"intelligence": 0,
		"cooking": 0,
		"crafting": 0,
	}
	level = 1
	total_xp = 0
	current_xp = 0

func _decay_stats(delta: float) -> void:
	_modify_stat("hunger", -HUNGER_RATE * delta)
	_modify_stat("thirst", -THIRST_RATE * delta)
	_modify_stat("energy", -ENERGY_RATE * delta)

func _regen_stats(delta: float) -> void:
	if stats["hunger"] > 20.0 and stats["thirst"] > 20.0:
		_modify_stat("health", HEALTH_REGEN_RATE * delta)

	if not Input.is_action_pressed("sprint"):
		_modify_stat("stamina", STAMINA_REGEN_RATE * delta)

	if stats["hunger"] < 20.0 or stats["thirst"] < 20.0:
		_modify_stat("stamina", -STAMINA_PENALTY_RATE * delta)
		_modify_stat("health", -0.5 * delta)

func _check_death() -> void:
	if stats["health"] <= 0.0:
		player_died.emit()

func _modify_stat(stat_name: String, amount: float) -> void:
	if not stats.has(stat_name):
		return
	var old_val := stats[stat_name]
	stats[stat_name] = clamp(stats[stat_name] + amount, 0.0, max_stats[stat_name])
	if abs(stats[stat_name] - old_val) > 0.01:
		stat_changed.emit(stat_name, stats[stat_name])

func add_skill_xp(skill_name: String, amount: int) -> void:
	if not skill_xp.has(skill_name):
		return
	skill_xp[skill_name] += amount
	var xp_needed := _xp_for_next_level(skills[skill_name])
	while skill_xp[skill_name] >= xp_needed:
		skill_xp[skill_name] -= xp_needed
		skills[skill_name] += 1
		skill_leveled_up.emit(skill_name, skills[skill_name])
		xp_needed = _xp_for_next_level(skills[skill_name])

func add_xp(amount: int) -> void:
	total_xp += amount
	current_xp += amount
	var xp_needed := level * 500
	while current_xp >= xp_needed:
		current_xp -= xp_needed
		level += 1
		_on_level_up()

func _xp_for_next_level(current_level: int) -> int:
	return current_level * 100

func _on_level_up() -> void:
	max_stats["health"] += 5.0
	max_stats["stamina"] += 5.0
	stats["health"] = max_stats["health"]
	stats["stamina"] = max_stats["stamina"]

func get_stat(stat_name: String) -> float:
	return stats.get(stat_name, 0.0)

func set_stat(stat_name: String, value: float) -> void:
	if not stats.has(stat_name):
		return
	stats[stat_name] = clamp(value, 0.0, max_stats[stat_name])
	stat_changed.emit(stat_name, stats[stat_name])

func serialize() -> Dictionary:
	return {
		"stats": stats,
		"max_stats": max_stats,
		"skills": skills,
		"skill_xp": skill_xp,
		"level": level,
		"total_xp": total_xp,
		"current_xp": current_xp,
	}

func deserialize(data: Dictionary) -> void:
	stats = data.get("stats", stats)
	max_stats = data.get("max_stats", max_stats)
	skills = data.get("skills", skills)
	skill_xp = data.get("skill_xp", skill_xp)
	level = data.get("level", level)
	total_xp = data.get("total_xp", total_xp)
	current_xp = data.get("current_xp", current_xp)

func get_weight_capacity() -> float:
	return 50.0 + float(skills["strength"] - 1) * 0.5
