## PhoneUI.gd
## Basic UI shell for phone apps, notifications, and app switching.
extends Control
class_name PhoneUI

var _title_label: Label
var _status_label: Label
var _notifications_label: Label
var _close_button: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	visible = false
	_build_ui()
	_refresh()

func _build_ui() -> void:
	var panel := Panel.new()
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-180, -220)
	panel.size = Vector2(360, 440)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 16
	vbox.offset_top = 16
	vbox.offset_right = -16
	vbox.offset_bottom = -16
	panel.add_child(vbox)

	_title_label = Label.new()
	_title_label.text = "Phone"
	_title_label.add_theme_font_size_override("font_size", 22)
	vbox.add_child(_title_label)

	_status_label = Label.new()
	_status_label.text = "Active app: home"
	vbox.add_child(_status_label)

	_notifications_label = Label.new()
	_notifications_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_notifications_label.text = "No notifications"
	vbox.add_child(_notifications_label)

	_close_button = Button.new()
	_close_button.text = "Close"
	_close_button.pressed.connect(_on_close_pressed)
	vbox.add_child(_close_button)

func _on_close_pressed() -> void:
	visible = false

func _refresh() -> void:
	if not is_instance_valid(PhoneSystem):
		_status_label.text = "Phone unavailable"
		_notifications_label.text = "No notifications"
		return
	_status_label.text = "Active app: %s" % PhoneSystem.active_app
	var notices := PhoneSystem.get_notifications()
	if notices.is_empty():
		_notifications_label.text = "No notifications"
	else:
		var text: PackedStringArray = []
		for note in notices:
			text.append("%s: %s" % [note["title"], note["message"]])
		_notifications_label.text = "\n".join(text)
