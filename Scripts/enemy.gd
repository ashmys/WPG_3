extends CharacterBody3D

const GRAVITY: float = 9.8

@export var nav_agent: NavigationAgent3D
@export var view: Area3D
@export var hear: AudioListener3D
@export var points: Array[Marker3D]
@export var player: CharacterBody3D
@export var speed_run: float = 5.0
@export var speed_walk: float = 2.0
@export var ray : RayCast3D

enum State { PATROL, CHASE, SEARCH, WAIT }
var state: State = State.PATROL

var last_seen_position: Vector3 = Vector3.ZERO
var last_seen_time: float = -2.0
var chase_memory_duration: float = 2.0
var current_patrol_point: Marker3D
var seen:bool = false
var wait_duration = 4.0          # how long to pause before patrol
var wait_timer = 0.0

func _ready() -> void:
	if !nav_agent or !player or points.is_empty():
		push_error("Missing references: nav_agent, player, or patrol points.")
		return

	current_patrol_point = points.pick_random()

func _physics_process(delta: float) -> void:
	if !is_on_floor():
		velocity.y -= GRAVITY * delta
		
	
	var dir = (player.global_position - global_position).normalized()
	ray.target_position = dir * 100  # panjang ray, misal 100 unit
	
	if ray.is_colliding():
		var hit = ray.get_collider()
		if hit == player:
			print("Player terlihat!")
	
<<<<<<< HEAD
	if result:
		seen = true
	else:
		seen = false
		
=======
>>>>>>> main
	match state:
		State.PATROL:
			if nav_agent.is_navigation_finished():
				current_patrol_point = points.pick_random()
			act(current_patrol_point.global_position, speed_walk, delta)

		State.CHASE:
			last_seen_position = player.global_position
			last_seen_time = Time.get_ticks_msec() / 1000.0
			act(player.global_position, speed_run, delta)
			wait_timer = 0.0  # reset wait timer

		State.SEARCH:
			if Time.get_ticks_msec() / 1000.0 - last_seen_time < chase_memory_duration:
				act(last_seen_position, speed_walk, delta)
			else:
				state = State.WAIT
				last_seen_time = 2.0
		
		State.WAIT:
			wait_timer += delta
			velocity.x = 0
			velocity.z = 0
			if wait_timer >= wait_duration:
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
