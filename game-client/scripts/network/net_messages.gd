## net_messages.gd
## Defines all network message types and helpers for the shared world architecture.
class_name NetMessages

## ──────────────────────────────────────────────
##  Message Types (Client → Server)
## ──────────────────────────────────────────────

const AUTH := "auth"
const SYNC := "sync"
const PLAYER_ACTION := "player_action"
const PLAYER_CHAT := "player_chat"
const PLAYER_INTERACT := "player_interact"
const REQUEST_WORLD_STATE := "request_world_state"
const REQUEST_REGION := "request_region"

## ──────────────────────────────────────────────
##  Message Types (Server → Client)
## ──────────────────────────────────────────────

const AUTH_OK := "auth_ok"
const AUTH_FAIL := "auth_fail"
const SYNC_OK := "sync_ok"
const WORLD_STATE := "world_state"
const REGION_DATA := "region_data"
const NPC_UPDATE := "npc_update"
const PLAYER_JOINED := "player_joined"
const PLAYER_LEFT := "player_left"
const ECONOMY_UPDATE := "economy_update"
const TIME_UPDATE := "time_update"
const ERROR_MSG := "error"

## ──────────────────────────────────────────────
##  Player Action Subtypes
## ──────────────────────────────────────────────

const ACTION_MOVE := "move"
const ACTION_INTERACT := "interact"
const ACTION_PURCHASE := "purchase"
const ACTION_ENTER_VEHICLE := "enter_vehicle"
const ACTION_EXIT_VEHICLE := "exit_vehicle"
const ACTION_ENTER_BUILDING := "enter_building"
const ACTION_EXIT_BUILDING := "exit_building"

## ──────────────────────────────────────────────
##  Helpers
## ──────────────────────────────────────────────

static func create_message(msg_type: String, data: Dictionary = {}) -> String:
	var msg := {"type": msg_type}
	msg.merge(data, true)
	return JSON.stringify(msg)

static func parse_message(raw: String) -> Dictionary:
	var parsed = JSON.parse_string(raw)
	if parsed is Dictionary:
		return parsed
	return {}

static func create_auth(token: String, player_id: String, version: String) -> String:
	return create_message(AUTH, {
		"token": token,
		"player_id": player_id,
		"version": version,
	})

static func create_sync(player_id: String, position: Vector3, velocity: Vector3 = Vector3.ZERO) -> String:
	return create_message(SYNC, {
		"player_id": player_id,
		"position": [position.x, position.y, position.z],
		"velocity": [velocity.x, velocity.y, velocity.z],
		"timestamp": Time.get_unix_time_from_system(),
	})

static func create_player_action(action: String, player_id: String, params: Dictionary = {}) -> String:
	var data := {"action": action, "player_id": player_id}
	data.merge(params, true)
	return create_message(PLAYER_ACTION, data)

static func vec3_from_array(arr: Array) -> Vector3:
	if arr.size() >= 3:
		return Vector3(arr[0], arr[1], arr[2])
	return Vector3.ZERO

static func vec3_to_array(v: Vector3) -> Array:
	return [v.x, v.y, v.z]
