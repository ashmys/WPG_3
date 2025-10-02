extends Node

# == NODE ==
@export var player: CharacterBody3D

# Internal state
var _saved_transform: Transform3D

func _toggle_hide(target: Object) -> void:
	if player.is_hiding:
		_unhide_player()
	else:
		_hide_player(target)

func _hide_player(target: Object) -> void:
	_saved_transform = player.global_transform

	if player.collider:
		player.collider.disabled = true
	player.has_gravity = false
	player.can_move = false

	# Move to hiding spot
	if target.hide_marker:
		player.global_transform = target.hide_marker.global_transform

	# Play hiding sound if method exists
	if target.has_method("play_object_sfx"):
		target.play_object_sfx()

	player.is_hiding = true
	print("Player is now hiding")

func _unhide_player() -> void:
	# Restore player interaction
	if player.collider:
		player.collider.disabled = false
	player.has_gravity = true
	player.can_move = true

	# Restore original position
	player.global_transform = _saved_transform

	player.is_hiding = false
	print("Player is no longer hiding")
