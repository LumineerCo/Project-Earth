## network_client.gd
## Low-level network client — manages WebSocket connection, message queueing,
## and reliable delivery. Used by WorldServerBridge for online mode.
class_name NetworkClient

extends Node

## ──────────────────────────────────────────────
##  Signals
## ──────────────────────────────────────────────

signal connected()
signal disconnected(code: int, reason: String)
signal message_received(message: Dictionary)
signal connection_error(error: String)

## ──────────────────────────────────────────────
##  State
## ──────────────────────────────────────────────

var _websocket: WebSocketPeer = WebSocketPeer.new()
var _is_connected: bool = false
var _url: String = ""
var _send_queue: Array[String] = []
var _reconnect_enabled: bool = true
var _reconnect_delay: float = 5.0
var _reconnect_timer: float = 0.0
var _max_queue_size: int = 1000

## ──────────────────────────────────────────────
##  Lifecycle
## ──────────────────────────────────────────────

func _process(delta: float) -> void:
	if _is_connected:
		_websocket.poll()
		_handle_state()
		_process_incoming()
		_flush_queue()
	elif _reconnect_enabled and not _url.is_empty():
		_reconnect_timer += delta
		if _reconnect_timer >= _reconnect_delay:
			_reconnect_timer = 0.0
			_connect()

## ──────────────────────────────────────────────
##  Connection
## ──────────────────────────────────────────────

func connect_to(url: String) -> void:
	_url = url
	_connect()

func _connect() -> void:
	var err := _websocket.connect_to_url(_url)
	if err != OK:
		connection_error.emit("Connection failed (error %d)" % err)
		DebugManager.log_error("NetworkClient", "Connect failed: %d" % err)
	else:
		DebugManager.log_info("NetworkClient", "Connecting to %s" % _url)

func disconnect() -> void:
	_reconnect_enabled = false
	_websocket.close()
	_is_connected = false

func _handle_state() -> void:
	var state := _websocket.get_ready_state()
	match state:
		WebSocketPeer.STATE_OPEN:
			if not _is_connected:
				_is_connected = true
				connected.emit()
				DebugManager.log_info("NetworkClient", "Connected")
		WebSocketPeer.STATE_CLOSED:
			if _is_connected:
				_is_connected = false
				var code := _websocket.get_close_code()
				var reason := _websocket.get_close_reason()
				disconnected.emit(code, reason)
				DebugManager.log_warn("NetworkClient", "Disconnected: %d %s" % [code, reason])

## ──────────────────────────────────────────────
##  Messaging
## ──────────────────────────────────────────────

func send(message: String) -> void:
	if _send_queue.size() >= _max_queue_size:
		_send_queue.pop_front()
	_send_queue.append(message)

func send_immediate(message: String) -> void:
	if _is_connected and _websocket.get_ready_state() == WebSocketPeer.STATE_OPEN:
		_websocket.send_text(message)
	else:
		send(message)

func _flush_queue() -> void:
	if not _is_connected or _websocket.get_ready_state() != WebSocketPeer.STATE_OPEN:
		return
	while not _send_queue.is_empty():
		var msg: String = _send_queue.pop_front()
		_websocket.send_text(msg)

func _process_incoming() -> void:
	while _websocket.get_available_packet_count() > 0:
		var packet := _websocket.get_packet()
		var text := packet.get_string_from_utf8()
		var parsed = JSON.parse_string(text)
		if parsed is Dictionary:
			message_received.emit(parsed)
		else:
			DebugManager.log_warn("NetworkClient", "Malformed message received")

## ──────────────────────────────────────────────
##  Status
## ──────────────────────────────────────────────

func is_connected_to_server() -> bool:
	return _is_connected

func get_queue_size() -> int:
	return _send_queue.size()

func get_ping() -> float:
	# TODO: implement RTT measurement
	return 0.0
