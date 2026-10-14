## NPCData.gd
## Lightweight data profile for an NPC instance.
## Stage 3.4 Step 2 (NPC Data Model)
class_name NPCData
extends RefCounted

var npc_id: String = ""
var first_name: String = ""
var last_name: String = ""
var npc_type: String = "citizen"  # citizen, worker, tourist, police, homeless
var home_position: Vector3 = Vector3.ZERO
var work_position: Vector3 = Vector3.ZERO
var current_state: String = "idle"  # idle, walking, fleeing, talking
var walk_speed: float = 1.4  # m/s
var run_speed: float = 4.0
var schedule: Dictionary = {}  # hour → activity

func full_name() -> String:
	return "%s %s" % [first_name, last_name]

func to_dict() -> Dictionary:
	return {
		"npc_id": npc_id,
		"first_name": first_name,
		"last_name": last_name,
		"npc_type": npc_type,
		"home_position": [home_position.x, home_position.y, home_position.z],
		"work_position": [work_position.x, work_position.y, work_position.z],
		"current_state": current_state,
		"walk_speed": walk_speed,
		"run_speed": run_speed,
		"schedule": schedule,
	}

static func from_dict(d: Dictionary) -> NPCData:
	var data := NPCData.new()
	data.npc_id = d.get("npc_id", "")
	data.first_name = d.get("first_name", "")
	data.last_name = d.get("last_name", "")
	data.npc_type = d.get("npc_type", "citizen")
	var hp: Array = d.get("home_position", [0, 0, 0])
	data.home_position = Vector3(hp[0], hp[1], hp[2])
	var wp: Array = d.get("work_position", [0, 0, 0])
	data.work_position = Vector3(wp[0], wp[1], wp[2])
	data.current_state = d.get("current_state", "idle")
	data.walk_speed = d.get("walk_speed", 1.4)
	data.run_speed = d.get("run_speed", 4.0)
	data.schedule = d.get("schedule", {})
	return data
