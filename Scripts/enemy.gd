extends CharacterBody3D

const GRAVITY_MULTIPLIER:= 4.5

@export_group("Nodes")
@export var collider: CollisionShape3D
@export var nav_agent: NavigationAgent3D
@export var area_view: Area3D
@export var ray_view: RayCast3D
@export var patrol_points: Array[Marker3D]
@export var player: CharacterBody3D
@export var game_overUI: Control

@export_group("Configs")
enum State { PATROL, CHASE, SEARCH, IDLE }
@export var state: State = State.IDLE
@export var is_patrol: bool = true
@export var speed_run: float = 5.0
@export var speed_walk: float = 2.0
@export var blend_speed: float = 15.0

var is_moving := false
var stuck := false

var patrol_index: int = 0
var player_visible: bool = false
var player_inside_view: bool = false
var last_seen_position: Vector3 = Vector3.ZERO
var last_seen_time: float = -2.0

var wait_timer: float = 0.0
var lost_sight_timer: float = 0.0

var searching_time: float = 10.0 
var waiting_time: float = 1.0

func _ready() -> void:
	if !nav_agent or !player or patrol_points.is_empty(): return
	patrol_index = 0
	_set_patrol_target()
	if is_patrol:
		state = State.PATROL
	#print("READY: Starting state =", state)

func _physics_process(delta: float) -> void:
	if velocity.x == 0.0 and velocity.z == 0.0:
		is_moving = false
	
	if not is_on_floor() and not stuck:
		_apply_gravity(delta)
	
	if Global.prolog:
		state = State.IDLE
	elif Global.stage1:
		state = State.IDLE
	elif Global.stage2:
		_check_visibility()
		_handle_state_transitions()
		_execute_state_behavior(delta)
		move_and_slide()
		_check_game_over()
	elif Global.stage3:
		_check_visibility()
		_handle_state_transitions()
		_execute_state_behavior(delta)
		move_and_slide()
		_check_game_over()
	elif Global.stage4:
		_check_visibility()
		_handle_state_transitions()
		_execute_state_behavior(delta)
		move_and_slide()
		_check_game_over()
	elif Global.stage5:
		_check_visibility()
		_handle_state_transitions()
		_execute_state_behavior(delta)
		move_and_slide()
		_check_game_over()


func _apply_gravity(delta: float) -> void:
	velocity += get_gravity() * GRAVITY_MULTIPLIER * delta

func _check_visibility() -> void:
	ray_view.target_position = ray_view.to_local(player.head.global_position)
	
	if not player or not ray_view or not area_view:
		player_visible = false
		return

	if player_inside_view and not ray_view.is_colliding():
		#print("Sees the player!")
		player_visible = true
	else:
		#print("Player left view area.")
		player_visible = false

	#print("Visibility check: player_visible = ", player_visible)


func _handle_state_transitions() -> void:
	if player_visible:
		state = State.CHASE
		last_seen_position = player.global_position
		last_seen_time = Time.get_ticks_msec() / 1000.0
		lost_sight_timer = 0.0
	elif state == State.CHASE:
		state = State.SEARCH

func _execute_state_behavior(delta: float) -> void:
	match state:
		State.PATROL:
			if nav_agent.is_navigation_finished():
				patrol_index = (patrol_index + 1) % patrol_points.size()
				_set_patrol_target()
			_act(nav_agent.get_target_position(), speed_walk, delta)
		State.CHASE:
			_act(player.global_position, speed_run, delta, true)
			wait_timer = 0.0
		State.SEARCH:
			var time_since_seen = Time.get_ticks_msec() / 1000.0 - last_seen_time
			if time_since_seen < searching_time:
				var offset = Vector3(randf() * 2 - 1, 0, randf() * 2 - 1).normalized() * 2.0
				#print("Searching near last seen at", last_seen_position + offset)
				_act(last_seen_position + offset, speed_run, delta)
			else:
				#print("Transition: SEARCH timeout, switching to IDLE")
				state = State.IDLE
		State.IDLE:
			wait_timer += delta
			velocity.x = 0.0
			velocity.z = 0.0
			if wait_timer >= waiting_time and is_patrol:
				#print("Wait over, resuming patrol")
				state = State.PATROL
				_set_patrol_target()

func _set_patrol_target() -> void:
	var target = patrol_points[patrol_index].global_position
	#print("Setting patrol target to", target)
	nav_agent.set_target_position(target)

func _act(target: Vector3, speed: float, delta: float, force_path: bool = false) -> void:
	if force_path or nav_agent.is_navigation_finished():
		#print("Setting new path to", target)
		nav_agent.set_target_position(target)
	var dest = nav_agent.get_next_path_position()
	if global_position.distance_to(target) < 0.5:
		velocity.x = 0.0
		velocity.z = 0.0
		#print("Arrived at target")
		return
	var dir = (dest - global_position).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed
	_face_target(dest, delta)
	is_moving = true

func _face_target(target: Vector3, delta: float) -> void:
	var dir = (target - global_position).normalized()
	dir.y = 0
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 5.0 * delta)

func _check_game_over() -> void:
	if global_position.distance_to(player.global_position) < 1.0 and not game_overUI.visible:
		#print("GAME OVER: Enemy reached player")
		game_overUI.visible = true
		state = State.IDLE
		await get_tree().create_timer(2.0).timeout
		get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
		Global.battery_count = 0
		Global.stage1 = false
		Global.stage2 = false
		Global.stage3 = false
		Global.generator_on = false
		Global.call_police = false
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == player:
		#print("Player entered detection area")
		player_inside_view = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body == player:
		#print("Player exited detection area")
		player_inside_view = false
		last_seen_position = player.global_position
		last_seen_time = Time.get_ticks_msec() / 1000.0

func _on_hear_sound() -> void:
	#print("Heard sound near player")
	last_seen_position = player.global_position
	last_seen_time = Time.get_ticks_msec() / 1000.0
	if state != State.CHASE:
		#print("Transition: Hearing triggers SEARCH")
		state = State.SEARCH
