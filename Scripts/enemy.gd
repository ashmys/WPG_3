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

# referensi ke AnimationTree
@onready var anim_tree: AnimationTree = $AnimationTree

enum State { PATROL, CHASE, SEARCH, WAIT }
var state: State = State.PATROL

# pilih jenis enemy di Inspector
enum EnemyType { COWOK, CEWEK }
@export var enemy_type: EnemyType = EnemyType.COWOK

# rute cowok dan cewek
var cowok_route: Array[int] = [3, 1, 6, 4, 7, 11, 8, 10, 13]
var cewek_route: Array[int] = [3, 2, 6, 3, 1, 5, 7, 12, 9]

var patrol_route: Array[int] = []
var patrol_index: int = 0
var current_patrol_point: Marker3D

var last_seen_position: Vector3 = Vector3.ZERO
var last_seen_time: float = -2.0
var chase_memory_duration: float = 2.0
var wait_duration = 4.0
var wait_timer = 0.0


func _ready() -> void:
	if !nav_agent or !player or points.is_empty():
		push_error("Missing references: nav_agent, player, or patrol points.")
		return

	# tentukan rute sesuai tipe enemy
	match enemy_type:
		EnemyType.COWOK:
			patrol_route = cowok_route
			$Bobby.visible = true
			$Valeria.visible = false
		EnemyType.CEWEK:
			patrol_route = cewek_route
			$Bobby.visible = false
			$Valeria.visible = true

	# mulai dari titik pertama
	patrol_index = 0
	current_patrol_point = points[patrol_route[patrol_index]]

	# langsung set target ke titik pertama biar ga dilewati
	nav_agent.set_target_position(current_patrol_point.global_position)

	# ray menghadap ke depan enemy
	ray.target_position = Vector3.FORWARD * 100
	
	# aktifkan animation tree
	anim_tree.active = true
	
	print(patrol_index)


func _physics_process(delta: float) -> void:
	velocity.y = 0  # biar tetap nempel di lantai

	match state:
		State.PATROL:
			
			if nav_agent.is_navigation_finished():
				# pindah ke titik berikutnya
				patrol_index = (patrol_index + 1) % patrol_route.size()
				current_patrol_point = points[patrol_route[patrol_index]]
				nav_agent.set_target_position(current_patrol_point.global_position)
			else:
				act(current_patrol_point.global_position, speed_walk, delta)

		State.CHASE:
			last_seen_position = player.global_position
			last_seen_time = Time.get_ticks_msec() / 1000.0
			act(player.global_position, speed_run, delta)
			wait_timer = 0.0  

		State.SEARCH:
			if Time.get_ticks_msec() / 1000.0 - last_seen_time < chase_memory_duration:
				act(last_seen_position, speed_walk, delta)
			else:
				state = State.WAIT

		State.WAIT:
			wait_timer += delta
			velocity.x = 0
			velocity.z = 0
			if wait_timer >= wait_duration:
				state = State.PATROL
				# reset ke target patrol selanjutnya
				nav_agent.set_target_position(current_patrol_point.global_position)

	move_and_slide()
	_update_animation()   # update animasi tiap frame


func act(target: Vector3, speed: float, delta: float) -> void:
	nav_agent.set_target_position(target)

	var destination = nav_agent.get_next_path_position()
	var dir = (destination - global_position).normalized()

	# sekarang ikut gerakan Y juga (bisa naik tangga)
	velocity.x = dir.x * speed
	velocity.y = dir.y * speed
	velocity.z = dir.z * speed

	face_target(destination, delta)


func face_target(target: Vector3, delta: float) -> void:
	var dir = (target - global_position).normalized()
	dir.y = 0
	rotation.y = lerp_angle(rotation.y, atan2(dir.x, dir.z), 5.0 * delta)


func _update_animation() -> void:
	var speed_val = velocity.length()
	if speed_val < 0.1:
		anim_tree.set("parameters/BlendSpace1D/blend_position", 0.0) # Idle
	elif speed_val < speed_run * 0.8:
		anim_tree.set("parameters/BlendSpace1D/blend_position", 1.0) # Walk
	else:
		anim_tree.set("parameters/BlendSpace1D/blend_position", 2.0) # Run


# kalau player masuk area penglihatan
func _on_area_3d_body_entered(body: Node3D) -> void:
	if body == player:
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
