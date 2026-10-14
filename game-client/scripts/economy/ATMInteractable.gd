## ATMInteractable.gd
## ATM terminal interactable for deposits, withdrawals, and balance checks.
## Stage 4.2 — Money & Banking
extends Area3D
class_name ATMInteractable

@export var atm_id: String = ""
@export var interaction_prompt: String = "Press E to use ATM"

var _player_inside: bool = false
var _prompt_label: Label3D = null

func _ready() -> void:
	if not body_entered.is_connected(_on_body_entered):
		body_entered.connect(_on_body_entered)
	if not body_exited.is_connected(_on_body_exited):
		body_exited.connect(_on_body_exited)

	_prompt_label = get_node_or_null("PromptLabel")
	if _prompt_label == null:
		_prompt_label = Label3D.new()
		_prompt_label.name = "PromptLabel"
		_prompt_label.font_size = 40
		_prompt_label.outline_size = 8
		_prompt_label.outline_modulate = Color.BLACK
		_prompt_label.billboard_mode = BaseMaterial3D.BILLBOARD_ENABLED
		_prompt_label.position = Vector3(0, 2.5, 0)
		add_child(_prompt_label)
	_prompt_label.visible = false

func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("Player"):
		return
	_player_inside = true
	_show_prompt()

func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("Player"):
		return
	_player_inside = false
	if _prompt_label:
		_prompt_label.visible = false

func interact(player: Node) -> void:
	if has_node("/root/ShopUIManager"):
		ShopUIManager.open_atm_ui()
	else:
		DebugManager.log_warn("ATMInteractable", "ATM UI manager not available")

func get_prompt() -> String:
	return interaction_prompt

func _show_prompt() -> void:
	if _prompt_label:
		_prompt_label.text = interaction_prompt
		_prompt_label.visible = true
