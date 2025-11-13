extends Node

@export var player: CharacterBody3D
@export var hide_duration: float = 1.0
@export var move_curve: Curve
@export var snap_threshold: float = 0.05
@export var items_group: Node3D

var _saved_transform: Transform3D
var _target_transform: Transform3D
var _transitioning: bool = false
var _unhiding: bool = false
var _progress: float = 0.0

var _start_basis: Basis
var _end_basis: Basis

func toggle_hide(target: Object) -> void:
	if player.is_hiding:
		_start_unhide_transition()
	else:
		_start_hide_transition(target)

	if Global.gameStage == Global.State.STAGE3:
		Global.gameStage = Global.State.STAGE4
	elif Global.gameStage == Global.State.STAGE5:
		Global.gameStage = Global.State.STAGE6

func _start_hide_transition(target: Object) -> void:
	_saved_transform = player.global_transform

	if player.collider:
		player.collider.disabled = true
	player.has_gravity = false
	player.can_move = false

	if target.hide_marker:
		_target_transform = target.hide_marker.global_transform
	else:
		_target_transform = target.global_transform

	_start_basis = player.global_transform.basis.orthonormalized()
	_end_basis = _compute_target_basis_toward_marker(_target_transform)

	_unhiding = false
	_progress = 0.0
	_transitioning = true
	items_group.visible = false

	if target.has_method("play_object_sfx"):
		target.play_object_sfx()

func _start_unhide_transition() -> void:
	var current_basis = player.global_transform.basis.orthonormalized()
	_start_basis = current_basis
	_end_basis = _saved_transform.basis.orthonormalized()

	_target_transform = Transform3D(_end_basis, _saved_transform.origin)

	_unhiding = true
	_progress = 0.0
	_transitioning = true
	items_group.visible = true

func _compute_target_basis_toward_marker(marker_xform: Transform3D) -> Basis:
	var marker_forward = -marker_xform.basis.z  # adjust if your “forward” is +z
	var up = Vector3.UP

	var dir = marker_forward
	if dir.is_zero_approx():
		return Basis.IDENTITY

	# Use the static method correctly:
	var target_basis = Basis.looking_at(dir, up)
	return target_basis.orthonormalized()

func _finalize_hide() -> void:
	player.is_hiding = true
	_transitioning = false

func _finalize_unhide() -> void:
	if player.collider:
		player.collider.disabled = false
	player.has_gravity = true
	player.can_move = true
	player.is_hiding = false
	_transitioning = false

func _physics_process(delta: float) -> void:
	if _transitioning:
		_update_transition(delta)

func _update_transition(delta: float) -> void:
	_progress += delta / hide_duration
	if _progress > 1.0:
		_progress = 1.0

	var factor = 1.0
	if move_curve:
		factor = move_curve.sample(_progress)

	# Position interpolation
	var start_pos = player.global_transform.origin
	var target_pos = _target_transform.origin
	var new_origin = start_pos.lerp(target_pos, factor)

	# Rotation interpolation using quaternions
	var qa = Quaternion(_start_basis)
	var qb = Quaternion(_end_basis)
	var qt = qa.slerp(qb, factor)
	var new_basis = Basis(qt).orthonormalized()

	player.global_transform = Transform3D(new_basis, new_origin)

	if _progress >= 1.0 or new_origin.distance_to(target_pos) < snap_threshold:
		player.global_transform = Transform3D(new_basis, target_pos)
		if _unhiding:
			_finalize_unhide()
		else:
			_finalize_hide()
