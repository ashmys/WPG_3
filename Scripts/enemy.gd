extends CharacterBody3D

const GRAVITY: float = 9.8

@export var nav_agent: NavigationAgent3D
@export var view: Area3D
@export var hear: AudioListener3D
@export var points: Array[Marker3D]
@export var player: CharacterBody3D
@export var speed_run: float = 5.0
@export var speed_walk: float = 2.0

enum State { PATROL, CHASE, SEARCH }
var state: State = State.PATROL

var last_seen_position: Vector3 = Vector3.ZERO
var last_seen_time: float = -1.0
var chase_memory_duration: float = 2.0
var current_patrol_point: Marker3D

func _ready() -> void:
	if !nav_agent or !player or points.is_empty():
		push_error("Missing references: nav_agent, player, or patrol points.")
		return

	current_patrol_point = points.pick_random()

func _physics_process(delta: float) -> void:
	if !is_on_floor():
		velocity.y -= GRAVITY * delta

	match state:
		State.PATROL:
			if nav_agent.is_navigation_finished():
				current_patrol_point = points.pick_random()
			act(current_patrol_point.global_position, speed_walk, delta)

		State.CHASE:
			last_seen_position = player.global_position
			last_seen_time = Time.get_ticks_msec() / 1000.0
			act(player.global_position, speed_run, delta)

		State.SEARCH:
			if Time.get_ticks_msec() / 1000.0 - last_seen_time < chase_memory_duration:
				act(last_seen_position, speed_walk, delta)
			else:
				state = State.PATROL

	move_and_slide()

func act(target: Vector3, speed: float, delta: float) -> void:
	nav_agent.set_target_position(target)

	var destination = nav_agent.get_next_path_position()
	var dir = (destination - global_position).normalized()

	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	face_target(destination, delta)

func face_target(target: Vector3, delta: float) -> void:
	var dir = (target - global_position).normalized()
	dir.y = 0
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 5.0 * delta)

# Triggered when player enters vision
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == player:
		state = State.CHASE

# Triggered when player leaves vision
func _on_area_3d_body_exited(body: Node3D) -> void:
	if body == player:
		state = State.SEARCH
		last_seen_position = player.global_position
		last_seen_time = Time.get_ticks_msec() / 1000.0

# Optional: triggered by hearing sound
func _on_hear_sound() -> void:
	last_seen_position = player.global_position
	last_seen_time = Time.get_ticks_msec() / 1000.0
	if state != State.CHASE:
		state = State.SEARCH
