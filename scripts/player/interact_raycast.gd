extends RayCast3D

# == EXPORTS & VARIABLES ==
@export_group("Nodes")
@export var player: CharacterBody3D
@export var hiding_mechanic: Node
@export var interact_mechanic: Node

var target: Object = null

func _physics_process(_delta: float) -> void:
	_update_collision_target()
	_update_popup_text()
	_process_interaction_input()


func _update_collision_target() -> void:
	# Reset target if no collision
	if not is_colliding():
		target = null
		return

	var collider = get_collider()
	# If collider is invalid or not in relevant groups, ignore it
	if collider == null:
		target = null
		return
	if not (collider.is_in_group("hide_object") or collider.is_in_group("interact_object")):
		target = null
		return

	target = collider


func _update_popup_text() -> void:
	# Decide whether to show or hide the popUpText, and update text
	if player.is_hiding:
		player.popUpText.text = str("Get out")
		player.popUpText.show()
		if Input.is_action_just_pressed("interact"):
			hiding_mechanic._toggle_hide(target)
	else:
		# When not hiding
		if target:
			player.popUpText.text = str(target.object_name)
			player.popUpText.show()
		else:
			player.popUpText.hide()


func _process_interaction_input() -> void:
	if not target:
		return

	if Input.is_action_just_pressed("interact"):
		if target.is_in_group("hide_object"):
			hiding_mechanic._toggle_hide(target)
		elif target.is_in_group("interact_object"):
			interact_mechanic._interact(target)
