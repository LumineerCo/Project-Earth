extends Label

var message := ""
var save_status := "No save action yet"

func update_overlay(player_position: Vector2, save_version: int, active_interactable_count: int, npc_count := 0, active_npc_count := 0, npc_summaries := []) -> void:
	var npc_text := ""
	for summary in npc_summaries:
		npc_text += "\n%s: %s -> %s" % [summary.get("name", "NPC"), summary.get("action", "idle"), summary.get("target", "")]
	text = "Project Earth Phase 2 | FPS: %s | Pos: %s | Save v%s | Interactables: %s | NPCs: %s/%s | %s%s" % [
		Engine.get_frames_per_second(),
		player_position.round(),
		save_version,
		active_interactable_count,
		active_npc_count,
		npc_count,
		save_status,
		npc_text,
	]
