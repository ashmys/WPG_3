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
@export var game_overUI:Control

# referensi ke AnimationTree
@onready var valeria_anim_tree = $Valeria/AnimationTree
@onready var bobby_anim_tree = $Bobby/AnimationTree

var vwalk_value = 0
var vrun_value = 0
var bwalk_value = 0
var brun_value = 0


enum State { PATROL, CHASE, SEARCH, WAIT }
var state: State = State.PATROL

enum {	VIDLE, VWALK, VRUN, BIDLE, BWALK, BRUN}
var curAnim

# pilih jenis enemy di Inspector
enum EnemyType { COWOK, CEWEK }
@export var enemy_type: EnemyType = EnemyType.CEWEK

# rute cowok dan cewek
var cowok_route: Array[int] = [3, 1, 6, 4, 7, 11, 8, 10, 13]
var cewek_route: Array[int] = [3, 2, 6, 3, 1, 5, 7, 12, 9]

var patrol_route: Array[int] = []
var patrol_index: int = 0
var current_patrol_point: Marker3D

var last_seen_position: Vector3 = Vector3.ZERO
var last_seen_time: float = -2.0
var chase_memory_duration: float = 6.0
var wait_duration = 4.0
var wait_timer = 0.0
var ray:bool = false
var lost_sight_grace: float = 2.0  # detik
var lost_sight_timer: float = 0.0



func _ready() -> void:
	game_overUI.visible = false
	
	if !nav_agent or !player or points.is_empty():
		push_error("Missing references: nav_agent, player, or patrol points.")
		return

	# tentukan rute sesuai tipe enemy
	match enemy_type:
		EnemyType.COWOK:
			patrol_route = cowok_route
			$Bobby.visible = true
			$Valeria.visible = false
			curAnim = BIDLE
			bobby_anim_tree.active = true
			
		EnemyType.CEWEK:
			patrol_route = cewek_route
			$Bobby.visible = false
			$Valeria.visible = true
			curAnim = VIDLE
			valeria_anim_tree.active = true

	# mulai dari titik pertama
	patrol_index = 0
	current_patrol_point = points[patrol_route[patrol_index]]

	# langsung set target ke titik pertama biar ga dilewati
	nav_agent.set_target_position(current_patrol_point.global_position)

	
	print(patrol_index)
	
func handle_animation(delta):
	match curAnim:
		VIDLE:
			vwalk_value = lerpf(vwalk_value,0,blend_speed*delta)
			vrun_value = lerpf(vrun_value,0,blend_speed*delta)
		VWALK:
			vwalk_value = lerpf(vwalk_value, 1.0, blend_speed*delta)
			vrun_value = lerpf(vrun_value,0,blend_speed*delta)
		VRUN:
			vwalk_value = lerpf(vwalk_value,0,blend_speed*delta)
			vrun_value = lerpf(vrun_value,1,blend_speed*delta)
		BIDLE:
			bwalk_value = lerpf(bwalk_value,0,blend_speed*delta)
			brun_value = lerpf(brun_value,0,blend_speed*delta)
		BWALK:
			bwalk_value = lerpf(bwalk_value,1,blend_speed*delta)
			brun_value = lerpf(brun_value,0,blend_speed*delta)
		BRUN:
			bwalk_value = lerpf(bwalk_value,0,blend_speed*delta)
			brun_value = lerpf(brun_value,1,blend_speed*delta)

func update_tree():
	valeria_anim_tree["parameters/Walk/blend_amount"] = vwalk_value
	valeria_anim_tree["parameters/Run/blend_amount"] = vrun_value
	bobby_anim_tree["parameters/Walk/blend_amount"] = bwalk_value
	bobby_anim_tree["parameters/Run/blend_amount"] = brun_value


func _physics_process(delta: float) -> void:
	velocity.y = 0  # biar tetap nempel di lantai

	# Cek apakah player terlihat (area + ray)
	var player_visible = false

	if view.overlaps_body(player):
		var space_state = get_world_3d().direct_space_state
		var query = PhysicsRayQueryParameters3D.create(global_position, player.global_position)
		var result = space_state.intersect_ray(query)
		if result and result["collider"] == player:
			player_visible = true

	# BONUS: kalau masih dekat (< 8 meter), tetap dianggap kelihatan meskipun ray terhalang
#	if distance_to_player < 8.0:
#		player_visible = true

	# Update state berdasarkan visibilitas
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
			if enemy_type == EnemyType.COWOK:
				curAnim = BWALK
			if enemy_type == EnemyType.CEWEK:
				curAnim = VWALK
			if nav_agent.is_navigation_finished():
				patrol_index = (patrol_index + 1) % patrol_route.size()
				current_patrol_point = points[patrol_route[patrol_index]]
				nav_agent.set_target_position(current_patrol_point.global_position)
			else:
				act(current_patrol_point.global_position, speed_walk, delta, false, true)

		State.CHASE:
			if enemy_type == EnemyType.COWOK:
				curAnim = BRUN
			if enemy_type == EnemyType.CEWEK:
				curAnim = VRUN
			last_seen_position = player.global_position
			last_seen_time = Time.get_ticks_msec() / 1000.0
			act(player.global_position, speed_run, delta, true, false)  # tanpa threshold
			wait_timer = 0.0

		State.SEARCH:
			if Time.get_ticks_msec() / 1000.0 - last_seen_time < chase_memory_duration:
				var random_offset = Vector3(randf() * 2 - 1, 0, randf() * 2 - 1).normalized() * 2.0
				act(last_seen_position + random_offset, speed_walk, delta)
			else:
				state = State.WAIT

		State.WAIT:
			if enemy_type == EnemyType.COWOK:
				curAnim = BIDLE
			if enemy_type == EnemyType.CEWEK:
				curAnim = VWALK
			wait_timer += delta
			velocity.x = 0
			velocity.z = 0
			if wait_timer >= wait_duration:
				state = State.PATROL
				# reset ke target patrol selanjutnya
				nav_agent.set_target_position(current_patrol_point.global_position)

	move_and_slide()
	handle_animation(delta)
	update_tree()

	# Cek apakah jarak sudah cukup dekat dengan player
	if global_position.distance_to(player.global_position) < 1.5:
		game_overUI.visible = true
		state = State.WAIT  # biar stop gerak setelah tangkap
		await get_tree().create_timer(2.0).timeout
		get_tree().call_deferred("reload_current_scene")


func act(target: Vector3, speed: float, delta: float, continuous: bool = false, use_threshold: bool = true) -> void:
	# Kalau chase: selalu update target
	if continuous:
		nav_agent.set_target_position(target)
	elif nav_agent.is_navigation_finished():
		nav_agent.set_target_position(target)

	var destination = nav_agent.get_next_path_position()

	# hanya PATROL yang pakai threshold jarak
	if use_threshold and global_position.distance_to(target) < 0.5:
		velocity.x = 0
		velocity.z = 0
		return

	var dir = (destination - global_position).normalized()
	velocity.x = dir.x * speed
	velocity.z = dir.z * speed

	face_target(destination, delta)

func face_target(target: Vector3, delta: float) -> void:
	var dir = (target - global_position).normalized()
	dir.y = 0
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 5.0 * delta)

# kalau player masuk area penglihatan
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == player:
		if ray == true:
			state = State.CHASE


# kalau player keluar area penglihatan
func _on_area_3d_body_exited(body: Node3D) -> void:
	if body == player:
		state = State.SEARCH
		last_seen_position = player.global_position
		last_seen_time = Time.get_ticks_msec() / 1000.0


# kalau enemy dengar suara (opsional)
func _on_hear_sound() -> void:
	last_seen_position = player.global_position
	last_seen_time = Time.get_ticks_msec() / 1000.0
	if state != State.CHASE:
		state = State.SEARCH
