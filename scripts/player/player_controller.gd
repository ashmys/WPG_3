extends CharacterBody3D

@export_group("Nodes")
@export var player_point: Node3D
@export var head: Node3D
@export var collider: CollisionShape3D
@export var push_component: PushAwayRigidBodies

@export_group("Configs")
@export var can_move := true
@export var has_gravity := true
@export var can_jump := true
@export var can_sprint := true
@export var can_freefly := false

@export_group("Speeds")
@export var base_speed := 7.0
@export var sprint_speed := 10.0
@export var jump_velocity := 16.0
@export var freefly_speed := 25.0
@export var rotation_speed := 10.0

@export_group("Input Actions")
@export var input_left := "move_left"
@export var input_right := "move_right"
@export var input_forward := "move_up"
@export var input_back := "move_down"
@export var input_interact := "interact"
@export var input_jump := "jump"
@export var input_sprint := "sprint"
@export var input_freefly := "freefly"

# == CONSTANTS ==
const GRAVITY_MULTIPLIER := 4.5

# == STATE ==
var input_dir := Vector2.ZERO
var is_moving := false
var is_sprint := false
var is_hiding:= false
var freeflying := false

# == UI NODES ==
@export_group("UI Nodes")
@export var popUpText: Label

func _unhandled_input(_event: InputEvent) -> void:
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		_toggle_freefly()

func _physics_process(delta: float) -> void:
	input_dir = Input.get_vector(input_left, input_right, input_forward, input_back)

	if can_freefly and freeflying:
		_handle_freefly(delta)
		return

	if has_gravity and not is_on_floor():
		velocity += get_gravity() * GRAVITY_MULTIPLIER * delta

	_handle_jump()
	_apply_movement(delta)

	push_component.apply_push_forces()
	move_and_slide()

# == MOVEMENT & PHYSICS ==

func _apply_movement(delta: float) -> void:
	if not can_move:
		velocity = Vector3.ZERO
		is_moving = false
		return

	is_sprint = can_sprint and Input.is_action_pressed(input_sprint)
	var current_speed = sprint_speed if is_sprint else base_speed

	var cam_basis = head.global_transform.basis
	var move_dir = (cam_basis.x * input_dir.x + cam_basis.z * input_dir.y)
	move_dir.y = 0
	if move_dir.length_squared() > 0:
		move_dir = move_dir.normalized()
		velocity.x = move_dir.x * current_speed
		velocity.z = move_dir.z * current_speed
		is_moving = true
	else:
		velocity.x = move_toward(velocity.x, 0, current_speed)
		velocity.z = move_toward(velocity.z, 0, current_speed)
		is_moving = false

	_update_model_rotation(move_dir, delta)

# == JUMPING ==

func _handle_jump() -> void:
	if can_jump and Input.is_action_just_pressed(input_jump) and is_on_floor():
		velocity.y = jump_velocity

# == FREEFLY ==

func _toggle_freefly() -> void:
	freeflying = not freeflying
	collider.disabled = freeflying
	if freeflying:
		velocity = Vector3.ZERO

func _handle_freefly(delta: float) -> void:
	var motion = head.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)
	move_and_collide(motion.normalized() * freefly_speed * delta)

# == VISUALS ==

func _update_model_rotation(move_dir: Vector3, delta: float) -> void:
	if move_dir.length_squared() > 0.0001:
		var target_angle = atan2(move_dir.x, move_dir.z)
		player_point.rotation.y = lerp_angle(player_point.rotation.y, target_angle, rotation_speed * delta)
