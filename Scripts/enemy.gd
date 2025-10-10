extends CharacterBody3D

const GRAVITY: float = 9.8

@export_group("Nodes")
@export var nav_agent: NavigationAgent3D
@export var view: Area3D
@export var points: Array[Marker3D]
@export var player: CharacterBody3D
@export var game_overUI: Control

@export_group("Configs")
@export var patrol_route: Array[int] = []
@export var speed_run: float = 5.0
@export var speed_walk: float = 2.0
@export var blend_speed: float = 15.0  # (type float)

@export_group("Enemy_Animtree")
@onready var anim_tree: AnimationTree

enum State { PATROL, CHASE, SEARCH, WAIT }
@export var state: State = State.PATROL

enum { IDLE, WALK, RUN }
var curAnim = IDLE

var patrol_index: int = 0
var current_patrol_point: Marker3D = null

var last_seen_position: Vector3 = Vector3.ZERO
var last_seen_time: float = -2.0
var chase_memory_duration: float = 6.0
var wait_duration: float = 4.0
var wait_timer: float = 0.0
var ray: bool = false
var lost_sight_grace: float = 2.0
var lost_sight_timer: float = 0.0

var patrol_cycle_count: int = 0
var trigger_spawn_cycle: int = 4

func _ready() -> void:
	game_overUI.visible = false

	# Null / sanity checks
	if nav_agent == null:
		push_error("nav_agent is not assigned!")
		return
	if player == null:
		push_error("player is not assigned!")
		return
	if points == null or points.is_empty():
		push_error("patrol points (points) are missing or empty!")
		return
	if anim_tree == null:
		push_error("anim_tree not assigned (or missing)!")
		# we can still proceed but animations won't work

	# Validate patrol_route indices
	for idx in patrol_route:
		if idx < 0 or idx >= points.size():
			push_error("patrol_route has invalid index: %d" % idx)
			return

	patrol_index = 0
	current_patrol_point = points[patrol_route[patrol_index]]
	# Immediately set nav_agent target so it starts moving
	nav_agent.set_target_position(current_patrol_point.global_position)


func _physics_process(delta: float) -> void:
	# Gravity
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0.0

	# Check if player is visible via area + raycast
	var player_visible = false
	if view != null and view.overlaps_body(player):
		var space_state = get_world_3d().direct_space_state
		var from_pos = global_position
		var to_pos = player.global_position
		var query = PhysicsRayQueryParameters3D.create(from_pos, to_pos)
		var result = space_state.intersect_ray(query)
		if result and result.has("collider") and result["collider"] == player:
			player_visible = true

	# Update state based on visibility
	if player_visible:
		state = State.CHASE
		lost_sight_timer = 0.0
		last_seen_position = player.global_position
		last_seen_time = Time.get_ticks_msec() / 1000.0
	else:
		if state == State.CHASE:
			lost_sight_timer += delta
			if lost_sight_timer >= lost_sight_grace:
				state = State.SEARCH

	# State logic
	match state:
		State.PATROL:
			curAnim = WALK
			if nav_agent.is_navigation_finished():
				patrol_index = (patrol_index + 1) % patrol_route.size()
				current_patrol_point = points[patrol_route[patrol_index]]
				nav_agent.set_target_position(current_patrol_point.global_position)
				if patrol_index == 0:
					patrol_cycle_count += 1
			else:
				act(current_patrol_point.global_position, speed_walk, delta, false, true)

		State.CHASE:
			curAnim = RUN
			last_seen_position = player.global_position
			last_seen_time = Time.get_ticks_msec() / 1000.0
			act(player.global_position, speed_run, delta, true, false)
			wait_timer = 0.0

		State.SEARCH:
			var elapsed = (Time.get_ticks_msec() / 1000.0) - last_seen_time
			if elapsed < chase_memory_duration:
				var random_offset = Vector3(randf() * 2 - 1, 0, randf() * 2 - 1).normalized() * 2.0
				act(last_seen_position + random_offset, speed_walk, delta)
			else:
				state = State.WAIT

		State.WAIT:
			curAnim = IDLE
			wait_timer += delta
			velocity.x = 0.0
			velocity.z = 0.0
			if wait_timer >= wait_duration:
				state = State.PATROL
				if current_patrol_point != null:
					nav_agent.set_target_position(current_patrol_point.global_position)

	# Actually move
	move_and_slide()

	# Capture / game over logic
	if player != null and global_position.distance_to(player.global_position) < 1.0:
		game_overUI.visible = true
		state = State.WAIT
		# wait then reload
		await get_tree().create_timer(2.0).timeout
		get_tree().call_deferred("reload_current_scene")


func act(target: Vector3, speed: float, delta: float, continuous: bool = false, use_threshold: bool = true) -> void:
	# continuous mode: always update target
	if continuous:
		nav_agent.set_target_position(target)
	else:
		if nav_agent.is_navigation_finished():
			nav_agent.set_target_position(target)

	var destination: Vector3 = nav_agent.get_next_path_position()

	if use_threshold and global_position.distance_to(target) < 0.5:
		velocity.x = 0.0
		velocity.z = 0.0
		return

	var dir = (destination - global_position).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	face_target(destination, delta)


func face_target(target: Vector3, delta: float) -> void:
	var dir = (target - global_position).normalized()
	dir.y = 0.0
	var desired = atan2(dir.x, dir.z)
	rotation.y = lerp_angle(rotation.y, desired, 5.0 * delta)


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == player:
		if ray:
			state = State.CHASE


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body == player:
		state = State.SEARCH
		last_seen_position = player.global_position
		last_seen_time = Time.get_ticks_msec() / 1000.0


func _on_hear_sound() -> void:
	last_seen_position = player.global_position
	last_seen_time = Time.get_ticks_msec() / 1000.0
	if state != State.CHASE:
		state = State.SEARCH
