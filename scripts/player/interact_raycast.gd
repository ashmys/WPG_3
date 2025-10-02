extends RayCast3D

# == EXPORTS & VARIABLES ==
@export_group("Nodes")
@export var player : CharacterBody3D
@export var hiding_mechanic : Node
@export var pickup_mechanic : Node

var target : Object = null

func _physics_process(_delta: float) -> void:
	if player.is_hiding:
		player.interactText.show()
		if Input.is_action_just_pressed("interact"):
			hiding_mechanic._toggle_hide(target)
	else:
		player.interactText.hide()

	#then check collider for hiding
	if not is_colliding():
		return

	target = get_collider()
	if target == null or (not target.is_in_group("hide_object") and not target.is_in_group("pickup_object")):
		return

	player.interactText.show()

	if Input.is_action_just_pressed("interact"):
		if target.is_in_group("hide_object"):
			hiding_mechanic._toggle_hide(target)
		if target.is_in_group("pickup_object"):
			pickup_mechanic._pickup(target)
