## NPCGenerator.gd
## Generates random NPC profiles with names, types, and schedules.
## Stage 3.4 Step 2
class_name NPCGenerator
extends RefCounted

const FIRST_NAMES := [
	"Alex", "Sam", "Jordan", "Taylor", "Morgan", "Casey", "Riley", "Quinn",
	"Avery", "Drew", "Jamie", "Reese", "Skyler", "Cameron", "Dakota", "Sage",
	"Maya", "Liam", "Noah", "Olivia", "Emma", "Lucas", "Mia", "Ethan",
	"Aria", "Leo", "Zoe", "Kai", "Nora", "Finn", "Ivy", "Owen",
]

const LAST_NAMES := [
	"Smith", "Johnson", "Williams", "Brown", "Jones", "Garcia", "Miller",
	"Davis", "Rodriguez", "Martinez", "Hernandez", "Lopez", "Gonzalez",
	"Wilson", "Anderson", "Thomas", "Taylor", "Moore", "Jackson", "Martin",
	"Lee", "Perez", "Thompson", "White", "Harris", "Sanchez", "Clark",
]

const NPC_TYPES := ["citizen", "worker", "tourist", "police", "homeless"]
const NPC_TYPE_WEIGHTS := [0.45, 0.30, 0.10, 0.05, 0.10]

## Generate a random NPC data profile.
static func generate_random(spawn_pos: Vector3 = Vector3.ZERO) -> NPCData:
	var data := NPCData.new()
	data.npc_id = "npc_%d" % [randi() % 1000000]
	data.first_name = FIRST_NAMES[randi() % FIRST_NAMES.size()]
	data.last_name = LAST_NAMES[randi() % LAST_NAMES.size()]
	data.npc_type = _weighted_random(NPC_TYPES, NPC_TYPE_WEIGHTS)
	data.home_position = spawn_pos
	data.walk_speed = randf_range(1.2, 1.8)
	data.run_speed = randf_range(3.5, 5.0)
	data.schedule = _generate_schedule(data.npc_type)
	return data

static func _weighted_random(items: Array, weights: Array) -> String:
	var total := 0.0
	for w in weights:
		total += w
	var r := randf() * total
	var cumulative := 0.0
	for i in range(items.size()):
		cumulative += weights[i]
		if r <= cumulative:
			return items[i]
	return items[0]

## Generate a daily schedule based on NPC type.
## Keys are hours (0-23), values are activity strings.
static func _generate_schedule(npc_type: String) -> Dictionary:
	var sched := {}
	match npc_type:
		"worker":
			sched[7] = "commute_to_work"
			sched[8] = "work"
			sched[12] = "lunch"
			sched[13] = "work"
			sched[17] = "commute_home"
			sched[18] = "home"
			sched[22] = "sleep"
		"tourist":
			sched[9] = "explore"
			sched[13] = "lunch"
			sched[14] = "explore"
			sched[19] = "rest"
			sched[23] = "sleep"
		"police":
			sched[6] = "patrol"
			sched[12] = "break"
			sched[13] = "patrol"
			sched[18] = "off_duty"
			sched[22] = "sleep"
		"homeless":
			sched[8] = "wander"
			sched[12] = "rest"
			sched[13] = "wander"
			sched[20] = "rest"
		_:  # citizen
			sched[7] = "home"
			sched[9] = "errands"
			sched[12] = "lunch"
			sched[14] = "leisure"
			sched[18] = "home"
			sched[22] = "sleep"
	return sched
