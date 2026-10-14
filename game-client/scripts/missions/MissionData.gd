## MissionData.gd
## Mission data scaffolding for Stage 4.6.
extends Resource
class_name MissionData

@export var mission_id: String = ""
@export var mission_name: String = ""
@export var description: String = ""
@export var giver_id: String = ""
@export var reward_money: int = 0
@export var reward_xp: int = 0
@export var required_items: Dictionary = {}
@export var active: bool = true

func to_dict() -> Dictionary:
	return {
		"mission_id": mission_id,
		"mission_name": mission_name,
		"description": description,
		"giver_id": giver_id,
		"reward_money": reward_money,
		"reward_xp": reward_xp,
		"required_items": required_items,
		"active": active,
	}

static func from_dict(data: Dictionary) -> MissionData:
	var mission := MissionData.new()
	mission.mission_id = data.get("mission_id", "")
	mission.mission_name = data.get("mission_name", "")
	mission.description = data.get("description", "")
	mission.giver_id = data.get("giver_id", "")
	mission.reward_money = int(data.get("reward_money", 0))
	mission.reward_xp = int(data.get("reward_xp", 0))
	mission.required_items = data.get("required_items", {})
	mission.active = bool(data.get("active", true))
	return mission
