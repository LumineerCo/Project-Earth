extends Area2D

@export var interaction_id := "interactable_test_notice"
@export var interaction_text := "Welcome to Project Earth Phase 1."

func interact(actor: Node) -> String:
	actor.set("last_interaction", interaction_text)
	return interaction_text
