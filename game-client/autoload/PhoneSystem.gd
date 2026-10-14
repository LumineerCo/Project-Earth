## PhoneSystem.gd
## Lightweight phone and notifications scaffold for Stage 4.4.
extends Node
class_name PhoneSystem

signal notification_added(title: String, message: String)
signal app_opened(app_name: String)

var notifications: Array[Dictionary] = []
var active_app: String = "home"

func _ready() -> void:
	add_notification("System", "Phone booted")

func add_notification(title: String, message: String) -> void:
	var entry := {
		"title": title,
		"message": message,
		"timestamp": Time.get_unix_time_from_system(),
	}
	notifications.append(entry)
	notification_added.emit(title, message)

func open_app(app_name: String) -> void:
	active_app = app_name
	app_opened.emit(app_name)

func get_notifications() -> Array[Dictionary]:
	return notifications

func serialize() -> Dictionary:
	return {
		"notifications": notifications,
		"active_app": active_app,
	}

func deserialize(data: Dictionary) -> void:
	notifications = data.get("notifications", notifications)
	active_app = data.get("active_app", active_app)
