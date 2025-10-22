extends CharacterBody3D

const GRAVITY: float = 9.8

@export var nav_agent: NavigationAgent3D
@export var view: Area3D
@export var hear: AudioListener3D
@export var points: Array[Marker3D]
@export var player: CharacterBody3D
@export var speed_run: float = 5.0
@export var speed_walk: float = 2.0
@export var blend_speed = 15
@export var game_overUI: Control

@onready var anim_tree = $Bobby/AnimationTree

var walk_value = 0.0
var run_value = 0.0

enum State { PATROL, CHASE, SEARCH, WAIT }
var state: State = State.PATROL

enum { IDLE, WALK, RUN }
var curAnim = IDLE

var patrol_route: Array[int] = [3, 1, 6, 4, 7, 11, 8, 10, 13]
var patrol_index: int = 0
var current_patrol_point: Marker3D

var last_seen_position: Vector3 = Vector3.ZERO
var last_seen_time: float = -2.0
var chase_memory_duration: float = 6.0
var wait_duration = 4.0
var wait_timer = 0.0
var lost_sight_timer: float = 0.0
var lost_sight_grace: float = 2.0

# optional anti-stuck
var stuck_timer = 0.0
var last_position = Vector3.ZERO

func _ready() -> void:
	game_overUI.visible = false

	# safety checks
	if !nav_agent or !player or points.is_empty():
		push_error("Missing references: nav_agent, player, or patrol points.")
		return

	# set initial patrol safely
	current_patrol_point = get_patrol_marker(patrol_index)
	if current_patrol_point:
		nav_agent.set_target_position(current_patrol_point.global_position)
	else:
		push_warning("No valid initial patrol point found.")

func get_patrol_marker(route_index: int) -> Marker3D:
	# ambil nilai dari patrol_route, pastikan index valid terhadap 'points'
	if points.is_empty():
		return null
	var route_val = patrol_route[route_index] if route_index < patrol_route.size() else patrol_route[route_index % patrol_route.size()]
	# safety: kalau route_val berada di rentang points
	if route_val >= 0 and route_val < points.size():
		return points[route_val]
	else:
		# fallback: gunakan modulo + warning supaya kamu tahu data route salah
		var safe_idx = int(route_val) % points.size()
		push_warning("patrol_route value %s out of range -> using %d instead" % [route_val, safe_idx])
		return points[safe_idx]

func handle_animation(delta):
	match curAnim:
		IDLE:
			walk_value = lerpf(walk_value, 0, blend_speed*delta)
			run_value = lerpf(run_value, 0, blend_speed*delta)
		WALK:
			walk_value = lerpf(walk_value, 1, blend_speed*delta)
			run_value = lerpf(run_value, 0, blend_speed*delta)
		RUN:
			walk_value = lerpf(walk_value, 0, blend_speed*delta)
			run_value = lerpf(run_value, 1, blend_speed*delta)

	anim_tree["parameters/Walk/blend_amount"] = walk_value
	anim_tree["parameters/Run/blend_amount"] = run_value

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	else:
		velocity.y = 0

	# deteksi player
	var player_visible = false
	if view and view.overlaps_body(player):
		var query = PhysicsRayQueryParameters3D.create(global_position, player.global_position)
		var result = get_world_3d().direct_space_state.intersect_ray(query)
		if result and result.has("collider") and result["collider"] == player:
			player_visible = true

	# update state
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

	match state:
		State.PATROL:
			curAnim = WALK
			# jika agent selesai, maju ke patrol berikutnya
			if nav_agent.is_navigation_finished():
				patrol_index = (patrol_index + 1) % patrol_route.size()
				current_patrol_point = get_patrol_marker(patrol_index)
				if current_patrol_point:
					nav_agent.set_target_position(current_patrol_point.global_position)
				else:
					push_warning("patrol point null after increment")
			else:
				if current_patrol_point:
					act(current_patrol_point.global_position, speed_walk, delta)
				else:
					# safety fallback: cari marker default
					current_patrol_point = get_patrol_marker(patrol_index)
					if current_patrol_point:
						nav_agent.set_target_position(current_patrol_point.global_position)

		State.CHASE:
			curAnim = RUN
			last_seen_position = player.global_position
			last_seen_time = Time.get_ticks_msec() / 1000.0
			act(player.global_position, speed_run, delta, true)
			wait_timer = 0.0

		State.SEARCH:
			if Time.get_ticks_msec() / 1000.0 - last_seen_time < chase_memory_duration:
				var offset = Vector3(randf() * 2 - 1, 0, randf() * 2 - 1).normalized() * 2.0
				act(last_seen_position + offset, speed_walk, delta)
			else:
				state = State.WAIT

		State.WAIT:
			curAnim = IDLE
			wait_timer += delta
			velocity.x = 0
			velocity.z = 0
			if wait_timer >= wait_duration:
				state = State.PATROL
				if current_patrol_point:
					nav_agent.set_target_position(current_patrol_point.global_position)

	# anti-stuck sederhana (opsional)
	if global_position.distance_to(last_position) < 0.02:
		stuck_timer += delta
		if stuck_timer > 2.0:
			# lompat ke patrol berikutnya kalau stuck
			patrol_index = (patrol_index + 1) % patrol_route.size()
			current_patrol_point = get_patrol_marker(patrol_index)
			if current_patrol_point:
				nav_agent.set_target_position(current_patrol_point.global_position)
			stuck_timer = 0.0
	else:
		stuck_timer = 0.0
	last_position = global_position

	move_and_slide()
	handle_animation(delta)

	# game over jika ketemu player
	if global_position.distance_to(player.global_position) < 1.5:
		game_overUI.visible = true
		state = State.WAIT
		await get_tree().create_timer(2.0).timeout
		get_tree().call_deferred("reload_current_scene")
		Global.battery_count = 0

func act(target: Vector3, speed: float, delta: float, continuous: bool = false) -> void:
	# set target kalau continuous atau kalau agent tidak punya path
	if continuous:
		nav_agent.set_target_position(target)
	elif nav_agent.is_navigation_finished():
		nav_agent.set_target_position(target)

	# ambil destination dengan guard
	var destination: Vector3 = nav_agent.get_next_path_position()
	if destination.is_equal_approx(Vector3.ZERO):
		# belum ada path atau path invalid -> fallback ke target langsung
		destination = nav_agent.get_target_position() if nav_agent.has_method("get_target_position") else target

	# jika sudah sampai target (pakai destination)
	if global_position.distance_to(destination) < 0.5:
		velocity.x = 0
		velocity.z = 0
		return

	# hindari normalisasi vektor nol
	var diff = destination - global_position
	if diff.length() <= 0.001:
		velocity.x = 0
		velocity.z = 0
		return

	var dir = diff.normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	face_target(destination, delta)

func face_target(target: Vector3, delta: float) -> void:
	var dir = (target - global_position)
	dir.y = 0
	if dir.length() > 0.001:
		dir = dir.normalized()
		rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 5.0 * delta)
