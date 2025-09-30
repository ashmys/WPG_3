extends RayCast3D

# == EXPORTS & VARIABLES ==
@export_group("Nodes")
@export var player : CharacterBody3D

var target : Object = null
var _saved_transform : Transform3D

func _physics_process(_delta: float) -> void:
	if player.is_hiding:
		player.interactText.show()
		if Input.is_action_just_pressed("interact"):
			_toggle_hide()
	else:
		player.interactText.hide()

	#then check collider for hiding
	if not is_colliding():
		return

	target = get_collider()
	if target == null or not target.is_in_group("hideable_objects"):
		return

	player.interactText.show()

	if Input.is_action_just_pressed("interact"):
		_toggle_hide()

func _toggle_hide() -> void:
	if player.is_hiding:
		_unhide_player()
	else:
		_hide_player()

func _hide_player() -> void:
	_saved_transform = player.global_transform

	player.collider.disabled = true
	player.has_gravity = false
	player.can_move = false

	# Move to hiding spot
	player.global_transform = target.hide_marker.global_transform

	target.play_object_sfx()
	player.is_hiding = true
	#print("Player is now hiding")

func _unhide_player() -> void:
	player.collider.disabled = false
	player.has_gravity = true
	player.can_move = true

	player.global_transform = _saved_transform

	player.is_hiding = false
	#print("Player is no longer hiding")
