## InventoryUI.gd
## Simple inventory display for the player.
## Stage 4.3 — Inventory System UI
extends Control
class_name InventoryUI

var _title_label: Label
var _items_box: VBoxContainer
var _close_button: Button

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_ui()

	if has_node("/root/ShopUIManager"):
		ShopUIManager.inventory_ui_opened.connect(_on_open)
		ShopUIManager.inventory_ui_closed.connect(_on_close)

	InventorySystem.inventory_changed.connect(_refresh_items)
	_refresh_items()

func _build_ui() -> void:
	var panel := Panel.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-260, -180)
	panel.size = Vector2(520, 360)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 16
	vbox.offset_top = 16
	vbox.offset_right = -16
	vbox.offset_bottom = -16
	panel.add_child(vbox)

	_title_label = Label.new()
	_title_label.text = "Inventory"
	_title_label.add_theme_font_size_override("font_size", 24)
	vbox.add_child(_title_label)

	_items_box = VBoxContainer.new()
	_items_box.custom_minimum_size = Vector2(0, 260)
	_items_box.add_theme_constant_override("separation", 6)
	vbox.add_child(_items_box)

	_close_button = Button.new()
	_close_button.text = "Close"
	_close_button.pressed.connect(_on_close_pressed)
	vbox.add_child(_close_button)

func _on_open() -> void:
	visible = true
	_refresh_items()

func _on_close() -> void:
	visible = false

func _refresh_items() -> void:
	for child in _items_box.get_children():
		child.queue_free()
	var any_items := false
	# Iterate over ALL slots (not just occupied ones) so the index matches
	# InventorySystem.slots indices used by use_item().
	var all_slots := InventorySystem.slots
	for i in range(all_slots.size()):
		var slot = all_slots[i]
		if slot["item_id"] == "":
			continue
		any_items = true
		var row := HBoxContainer.new()
		row.add_theme_constant_override("separation", 8)

		var icon_rect := TextureRect.new()
		icon_rect.custom_minimum_size = Vector2(32, 32)
		icon_rect.expand_mode = TextureRect.EXPAND_FIT_WIDTH_PROPORTIONAL
		icon_rect.stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED
		var item_data := slot["item_data"] as ItemData
		if item_data and item_data.icon:
			icon_rect.texture = item_data.icon
		else:
			icon_rect.modulate = Color(0.5, 0.5, 0.5, 0.4)
		row.add_child(icon_rect)

		var item_label := Label.new()
		item_label.text = "%s x%d" % [item_data.display_name if item_data else slot["item_id"], slot["count"]]
		item_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL
		row.add_child(item_label)

		if item_data and item_data.value > 0:
			var value_label := Label.new()
			value_label.text = "%d Cr" % item_data.value
			value_label.modulate = Color(1, 0.85, 0.3)
			row.add_child(value_label)

		# Quick-use button (only for usable items)
		if item_data and item_data.usable:
			var use_btn := Button.new()
			use_btn.text = "Use"
			use_btn.pressed.connect(_on_use_pressed.bind(i))
			row.add_child(use_btn)

		# Drop button
		var drop_btn := Button.new()
		drop_btn.text = "Drop"
		drop_btn.pressed.connect(_on_drop_pressed.bind(i))
		row.add_child(drop_btn)

		_items_box.add_child(row)
	if not any_items:
		var empty_label := Label.new()
		empty_label.text = "(empty)"
		empty_label.modulate = Color(0.6, 0.6, 0.6)
		_items_box.add_child(empty_label)

func _on_use_pressed(slot_index: int) -> void:
	InventorySystem.use_item(slot_index)
	_refresh_items()

func _on_drop_pressed(slot_index: int) -> void:
	var slot = InventorySystem.slots[slot_index]
	if slot["item_id"] != "":
		InventorySystem.remove_item(slot["item_id"], slot["count"])
		_refresh_items()

func _on_close_pressed() -> void:
	if has_node("/root/ShopUIManager"):
		ShopUIManager.close_inventory_ui()
	visible = false
