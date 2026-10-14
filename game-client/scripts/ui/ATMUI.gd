## ATMUI.gd
## Simple ATM interface for depositing and withdrawing cash.
## Stage 4.2 — Money & Banking UI
extends Control
class_name ATMUI

var _balance_label: Label
var _cash_label: Label
var _amount_input: LineEdit
var _deposit_button: Button
var _withdraw_button: Button
var _close_button: Button
var _message_label: Label

func _ready() -> void:
	set_anchors_preset(Control.PRESET_FULL_RECT)
	mouse_filter = Control.MOUSE_FILTER_STOP
	visible = false
	_build_ui()

	if has_node("/root/ShopUIManager"):
		ShopUIManager.atm_ui_opened.connect(_on_open)
		ShopUIManager.atm_ui_closed.connect(_on_close)

	if MoneySystem:
		MoneySystem.bank_changed.connect(_update_display)
		MoneySystem.cash_changed.connect(_update_display)
	_update_display()

func _build_ui() -> void:
	var panel := Panel.new()
	panel.name = "Panel"
	panel.set_anchors_preset(Control.PRESET_CENTER)
	panel.position = Vector2(-200, -140)
	panel.size = Vector2(400, 280)
	add_child(panel)

	var vbox := VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.offset_left = 16
	vbox.offset_top = 16
	vbox.offset_right = -16
	vbox.offset_bottom = -16
	panel.add_child(vbox)

	var title := Label.new()
	title.text = "ATM"
	title.add_theme_font_size_override("font_size", 24)
	vbox.add_child(title)

	_balance_label = Label.new()
	_balance_label.text = "Bank: 0"
	vbox.add_child(_balance_label)

	_cash_label = Label.new()
	_cash_label.text = "Cash: 0"
	vbox.add_child(_cash_label)

	_amount_input = LineEdit.new()
	_amount_input.placeholder_text = "Amount"
	_amount_input.text = "0"
	vbox.add_child(_amount_input)

	var button_row := HBoxContainer.new()
	button_row.custom_minimum_size = Vector2(0, 40)
	vbox.add_child(button_row)

	_deposit_button = Button.new()
	_deposit_button.text = "Deposit"
	_deposit_button.pressed.connect(_on_deposit_pressed)
	button_row.add_child(_deposit_button)

	_withdraw_button = Button.new()
	_withdraw_button.text = "Withdraw"
	_withdraw_button.pressed.connect(_on_withdraw_pressed)
	button_row.add_child(_withdraw_button)

	_message_label = Label.new()
	_message_label.text = ""
	vbox.add_child(_message_label)

	_close_button = Button.new()
	_close_button.text = "Close"
	_close_button.pressed.connect(_on_close_pressed)
	vbox.add_child(_close_button)

func _on_open() -> void:
	visible = true
	_update_display()

func _on_close() -> void:
	visible = false

func _update_display() -> void:
	_balance_label.text = "Bank: %d Cr" % MoneySystem.bank_balance if MoneySystem else "Bank: --"
	_cash_label.text = "Cash: %d Cr" % MoneySystem.cash if MoneySystem else "Cash: --"

func _on_deposit_pressed() -> void:
	var amount := int(_amount_input.text)
	if amount <= 0:
		_show_message("Enter a valid positive amount")
		return
	if MoneySystem and MoneySystem.deposit(amount):
		_update_display()
		_show_message("Deposited %d Cr" % amount)
	else:
		_show_message("Insufficient cash")

func _on_withdraw_pressed() -> void:
	var amount := int(_amount_input.text)
	if amount <= 0:
		_show_message("Enter a valid positive amount")
		return
	if MoneySystem and MoneySystem.withdraw(amount):
		_update_display()
		_show_message("Withdrew %d Cr" % amount)
	else:
		_show_message("Insufficient balance")

func _on_close_pressed() -> void:
	if has_node("/root/ShopUIManager"):
		ShopUIManager.close_atm_ui()
	visible = false

func _show_message(text: String) -> void:
	_message_label.text = text
