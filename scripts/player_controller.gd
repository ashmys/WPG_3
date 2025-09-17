extends CharacterBody3D

# == CONFIGURATION ==

@export var can_move := true
@export var has_gravity := true
@export var can_jump := true
@export var can_dash := true
@export var can_sprint := false
@export var can_freefly := false

@export_group("Speeds")
@export var base_speed := 7.0
@export var sprint_speed := 10.0
@export var dash_speed := 16.0
@export var dash_duration := 0.3
@export var dash_cooldown := 0.5
@export var jump_velocity := 16.0
@export var freefly_speed := 25.0
@export var rotation_speed := 10.0

@export_group("Input Actions")
@export var input_left := "move_left"
@export var input_right := "move_right"
@export var input_forward := "move_up"
@export var input_back := "move_down"
@export var input_attack := "attack"
@export var input_jump := "jump"
@export var input_dash := "dash"
@export var input_sprint := "sprint"
@export var input_freefly := "freefly"

# == VARIABLE ==
var target

# == CONSTANTS ==
const GRAVITY_MULTIPLIER := 4.5

# == STATE ==
var input_dir := Vector2.ZERO
var move_speed := 0.0
var is_moving := false
var is_dashing := false
var freeflying := false

# == DASH ==
var dash_ready := true
var dash_time_left := 0.0
var dash_cooldown_left := 0.0
var dash_direction := Vector3.ZERO

# == NODES ==
@export_group("Nodes")
@export var player_point : Node3D
@export var head : Node3D
@export var interact_raycast : RayCast3D
@export var collider : CollisionShape3D
var state_machine

# == ENGINE CALLBACKS ==

#func _ready() -> void:
	#pass

func _unhandled_input(_event: InputEvent) -> void:
	if can_freefly and Input.is_action_just_pressed(input_freefly):
		_toggle_freefly()

func _physics_process(delta: float) -> void:
	input_dir = Input.get_vector(input_left, input_right, input_forward, input_back)
	_update_dash_cooldown(delta)

	if interact_raycast.is_colliding():
		target = interact_raycast.get_collider()
		print(target)

	if can_freefly and freeflying:
		_handle_freefly(delta)
		return

	if has_gravity and not is_on_floor():
		_apply_gravity(delta)

	_handle_jump()
	_handle_dash_start()
	_handle_dash_motion(delta)

	if not is_dashing:
		_apply_movement(delta)

	move_and_slide()

# == MOVEMENT & PHYSICS ==

func _apply_gravity(delta: float) -> void:
	velocity += get_gravity() * GRAVITY_MULTIPLIER * delta

func _apply_movement(delta: float) -> void:
	if not can_move:
		velocity.x = 0
		velocity.z = 0
		return

	move_speed = sprint_speed if can_sprint and Input.is_action_pressed(input_sprint) else base_speed
	var head_basis = Basis(Vector3.UP, head.rotation.y)
	var move_dir = (head_basis * Vector3(input_dir.x, 0, input_dir.y))

	if move_dir.length() > 0:
		move_dir = move_dir.normalized()
		velocity.x = move_dir.x * move_speed
		velocity.z = move_dir.z * move_speed
		is_moving = true
	else:
		velocity.x = move_toward(velocity.x, 0, move_speed)
		velocity.z = move_toward(velocity.z, 0, move_speed)
		is_moving = false

	_update_model_rotation(move_dir, delta)

# == JUMPING ==

func _handle_jump() -> void:
	if can_jump and Input.is_action_just_pressed(input_jump) and is_on_floor():
		velocity.y = jump_velocity

# == DASHING ==

func _update_dash_cooldown(delta: float) -> void:
	if not dash_ready:
		dash_cooldown_left -= delta
		if dash_cooldown_left <= 0.0:
			dash_ready = true

func _handle_dash_start() -> void:
	if not (can_dash and not is_dashing and dash_ready):
		return

	if Input.is_action_just_pressed(input_dash) and input_dir.length() > 0.1:
		is_dashing = true
		dash_time_left = dash_duration
		var head_basis = Basis(Vector3.UP, head.rotation.y)
		dash_direction = (head_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
		dash_ready = false
		dash_cooldown_left = dash_cooldown

func _handle_dash_motion(delta: float) -> void:
	if not is_dashing:
		return

	dash_time_left -= delta
	var dash_progress = (dash_duration - dash_time_left) / dash_duration
	var head_basis = Basis(Vector3.UP, head.rotation.y)
	var move_dir = (head_basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	if dash_progress >= 1.0 / 3.0 and move_dir.length() > 0.1:
		move_speed = sprint_speed if can_sprint and Input.is_action_pressed(input_sprint) else base_speed
		var combined_dir = (dash_direction * dash_speed + move_dir * move_speed).normalized()
		velocity.x = combined_dir.x * dash_speed
		velocity.z = combined_dir.z * dash_speed
	else:
		velocity.x = dash_direction.x * dash_speed
		velocity.z = dash_direction.z * dash_speed

	if dash_time_left <= 0.0:
		is_dashing = false

	_update_model_rotation(move_dir if move_dir.length() > 0.1 else dash_direction, delta)

# == FREEFLY ==

func _toggle_freefly() -> void:
	if freeflying:
		_disable_freefly()
	else:
		_enable_freefly()

func _enable_freefly() -> void:
	collider.disabled = true
	freeflying = true
	velocity = Vector3.ZERO

func _disable_freefly() -> void:
	collider.disabled = false
	freeflying = false

func _handle_freefly(delta: float) -> void:
	var motion = (head.global_transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized() * freefly_speed * delta
	move_and_collide(motion)

# == VISUALS ==

func _update_model_rotation(move_dir: Vector3, delta: float) -> void:
	if move_dir.length() > 0.01:
		var target_angle = atan2(move_dir.x, move_dir.z)
		player_point.rotation.y = lerp_angle(player_point.rotation.y, target_angle, rotation_speed * delta)
