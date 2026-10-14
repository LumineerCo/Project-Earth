## WorldServerBridge.gd
## Bridges the client to the authoritative world server (online mode) or
## runs the same server logic embedded (offline mode). Manages connection,
## state sync, and graceful fallback.
extends Node
class_name WorldServerBridge

## ──────────────────────────────────────────────
##  Enums & Signals
## ──────────────────────────────────────────────

enum ConnectionMode {
	OFFLINE,
	CONNECTING,
	ONLINE,
	DISCONNECTED,
	ERROR
}

signal mode_changed(new_mode: ConnectionMode)
signal sync_completed()
signal sync_failed(reason: String)

## ──────────────────────────────────────────────
##  Configuration
## ──────────────────────────────────────────────

const DEFAULT_SERVER_URL := "ws://localhost:8080"
const RECONNECT_DELAY := 5.0
const MAX_RECONNECT_ATTEMPTS := 3
const SYNC_INTERVAL := 0.1  # 100ms = 10 ticks/sec

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var current_mode: ConnectionMode = ConnectionMode.OFFLINE
var server_url: String = DEFAULT_SERVER_URL
var _websocket: WebSocketPeer = null
var _reconnect_attempts: int = 0
var _reconnect_timer: float = 0.0
var _is_reconnect_pending: bool = false
var _sync_timer: float = 0.0
var _is_authenticated: bool = false
var _auth_token: String = ""
var _player_id: String = ""

## Embedded local server (runs same logic as remote server)
var _local_server: Object = null

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _ready() -> void:
	_websocket = WebSocketPeer.new()
	DebugManager.log_info("WorldServerBridge", "Initialized (default mode: OFFLINE)")

func _process(delta: float) -> void:
	# Handle pending reconnect countdown (applies in any mode)
	if _is_reconnect_pending:
		_reconnect_timer += delta
		if _reconnect_timer >= RECONNECT_DELAY:
			_reconnect_timer = 0.0
			_is_reconnect_pending = false
			_do_reconnect()
		return
	match current_mode:
		ConnectionMode.ONLINE:
			_process_online(delta)
		ConnectionMode.CONNECTING:
			_process_connecting()
		_:
			_process_offline(delta)

func _exit_tree() -> void:
	disconnect_from_server()

## ──────────────────────────────────────────────
##  Mode Management
## ──────────────────────────────────────────────

func start_offline() -> void:
	_set_mode(ConnectionMode.OFFLINE)
	# Start embedded local server
	if not _local_server:
		_local_server = ClassDB.instantiate("LocalWorldServer") if ClassDB.class_exists("LocalWorldServer") else null
	DebugManager.log_info("WorldServerBridge", "Started in OFFLINE mode (embedded server)")

func connect_to_server(url: String = DEFAULT_SERVER_URL, token: String = "") -> void:
	server_url = url
	_auth_token = token
	_set_mode(ConnectionMode.CONNECTING)
	var err := _websocket.connect_to_url(url)
	if err != OK:
		DebugManager.log_error("WorldServerBridge", "Failed to connect to %s (error %d)" % [url, err])
		_set_mode(ConnectionMode.ERROR)
		sync_failed.emit("Connection failed")
	else:
		DebugManager.log_info("WorldServerBridge", "Connecting to %s..." % url)

func disconnect_from_server() -> void:
	if _websocket:
		_websocket.close()
	_set_mode(ConnectionMode.OFFLINE)
	_is_authenticated = false
	DebugManager.log_info("WorldServerBridge", "Disconnected from server")

func is_online() -> bool:
	return current_mode == ConnectionMode.ONLINE and _is_authenticated

## ──────────────────────────────────────────────
##  Online Processing
## ──────────────────────────────────────────────

func _process_connecting() -> void:
	_websocket.poll()
	var state := _websocket.get_ready_state()
	match state:
		WebSocketPeer.STATE_OPEN:
			DebugManager.log_info("WorldServerBridge", "Connected to server")
			_send_auth()
		WebSocketPeer.STATE_CLOSED:
			var code := _websocket.get_close_code()
			var reason := _websocket.get_close_reason()
			DebugManager.log_error("WorldServerBridge", "Connection closed: %d %s" % [code, reason])
			_handle_disconnect()

func _process_online(delta: float) -> void:
	_websocket.poll()
	var state := _websocket.get_ready_state()
	if state != WebSocketPeer.STATE_OPEN:
		_handle_disconnect()
		return
	
	# Process incoming messages
	while _websocket.get_available_packet_count() > 0:
		var packet := _websocket.get_packet()
		var message := packet.get_string_from_utf8()
		_handle_message(message)
	
	# Periodic sync
	_sync_timer += delta
	if _sync_timer >= SYNC_INTERVAL:
		_sync_timer = 0.0
		_send_sync()

func _handle_disconnect() -> void:
	_is_authenticated = false
	if _reconnect_attempts < MAX_RECONNECT_ATTEMPTS:
		_reconnect_attempts += 1
		DebugManager.log_warn("WorldServerBridge", "Reconnect attempt %d/%d in %.1fs" % [_reconnect_attempts, MAX_RECONNECT_ATTEMPTS, RECONNECT_DELAY])
		_set_mode(ConnectionMode.DISCONNECTED)
		_reconnect_timer = 0.0
		_is_reconnect_pending = true
	else:
		DebugManager.log_error("WorldServerBridge", "Max reconnect attempts reached — falling back to offline")
		_set_mode(ConnectionMode.OFFLINE)
		sync_failed.emit("Max reconnect attempts reached")

## Called after RECONNECT_DELAY elapses — creates a fresh WebSocketPeer before reconnecting
func _do_reconnect() -> void:
	# Discard the old peer (may be in a bad state) and create a fresh one
	_websocket = WebSocketPeer.new()
	_set_mode(ConnectionMode.CONNECTING)
	var err := _websocket.connect_to_url(server_url)
	if err != OK:
		DebugManager.log_error("WorldServerBridge", "Reconnect failed (error %d)" % err)
		_handle_disconnect()
	else:
		DebugManager.log_info("WorldServerBridge", "Reconnecting to %s..." % server_url)

## ──────────────────────────────────────────────
##  Offline Processing
## ──────────────────────────────────────────────

func _process_offline(delta: float) -> void:
	# Run embedded server logic
	_sync_timer += delta
	if _sync_timer >= SYNC_INTERVAL:
		_sync_timer = 0.0
		# In offline mode, the local server processes directly
		# No network overhead — state is local
		pass

## ──────────────────────────────────────────────
##  Messaging
## ──────────────────────────────────────────────

func _send_auth() -> void:
	var msg := JSON.stringify({
		"type": "auth",
		"token": _auth_token,
		"player_id": GameManager.player_data.get("player_id", ""),
		"version": GameManager.game_version,
	})
	_send_message(msg)

func _send_sync() -> void:
	var msg := JSON.stringify({
		"type": "sync",
		"player_id": _player_id,
		"position": GameManager.player_data.get("position", Vector3.ZERO),
		"timestamp": Time.get_unix_time_from_system(),
	})
	_send_message(msg)

func _send_message(message: String) -> void:
	if _websocket and _websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_websocket.send_text(message)

func _handle_message(message: String) -> void:
	var parsed = JSON.parse_string(message)
	if not parsed is Dictionary:
		return
	var msg_type: String = parsed.get("type", "")
	match msg_type:
		"auth_ok":
			_is_authenticated = true
			_player_id = parsed.get("player_id", "")
			_set_mode(ConnectionMode.ONLINE)
			_reconnect_attempts = 0
			_is_reconnect_pending = false
			_reconnect_timer = 0.0
			DebugManager.log_info("WorldServerBridge", "Authenticated as %s" % _player_id)
			sync_completed.emit()
		"auth_fail":
			DebugManager.log_error("WorldServerBridge", "Authentication failed: %s" % parsed.get("reason", ""))
			_set_mode(ConnectionMode.ERROR)
			sync_failed.emit("Authentication failed")
		"sync_ok":
			sync_completed.emit()
		"world_state":
			_apply_world_state(parsed.get("state", {}))
		"error":
			DebugManager.log_error("WorldServerBridge", "Server error: %s" % parsed.get("message", ""))
		_:
			DebugManager.log_debug("WorldServerBridge", "Unknown message type: %s" % msg_type)

func _apply_world_state(state: Dictionary) -> void:
	# Apply received world state to local systems
	DebugManager.log_debug("WorldServerBridge", "Applied world state update")

## ──────────────────────────────────────────────
##  Internal
## ──────────────────────────────────────────────

func _set_mode(new_mode: ConnectionMode) -> void:
	if new_mode == current_mode:
		return
	current_mode = new_mode
	mode_changed.emit(new_mode)
	GameManager.is_online = (new_mode == ConnectionMode.ONLINE)
