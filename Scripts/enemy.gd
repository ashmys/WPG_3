extends CharacterBody3D

const GRAVITY = 9.8

@export var nav_agent: NavigationAgent3D
@export var view : Area3D
@export var hear : AudioListener3D

@export var point: Array[Marker3D]
@export var player : CharacterBody3D
@export var speedRun: int = 5
@export var speedWalk: int = 5

enum State { PATROL, CHASE, SEARCH }
var state: State = State.PATROL
var area3d: bool = false
var last_seen_position: Vector3 = Vector3.ZERO
var last_seen_time: float = -1.0
var chase_memory: float = 2.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta

	# Debug: Current state and velocity
	print("State:", state, " | Velocity:", velocity)

	if Global.sound == true:
		print("[DEBUG] Sound detected at: ", Global.source)
		nav_agent.set_target_position(Global.source)
		var destination = nav_agent.get_next_path_position()
		var local_destination = destination - global_position
		var direction = local_destination.normalized()

		var target_pos = destination
		target_pos.y = global_position.y
		face_target(destination, delta)

		if nav_agent.is_navigation_finished():
			print("[DEBUG] Reached sound location.")
			Global.sound = false
			return

	if not player:
		print("[DEBUG] Player reference missing!")
		return

	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var from = global_transform.origin + Vector3.UP * 1.0
	var to = player.global_transform.origin + Vector3.UP * 1.0

	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]

	var result: Dictionary = space.intersect_ray(query)

	if result and (result.collider == player or result.collider.get_parent() == player):
		if area3d:
			print("[DEBUG] Player in view and in area3d!")
			Global.sound = false
			last_seen_position = player.global_transform.origin
			last_seen_time = Time.get_ticks_msec() / 1000.0
			print("[DEBUG] Last seen position:", last_seen_position)
			nav_agent.set_target_position(last_seen_position)

	elif last_seen_time > 0 and (Time.get_ticks_msec() / 1000.0 - last_seen_time < chase_memory):
		print("[DEBUG] Chasing memory to last known position:", last_seen_position)
		nav_agent.set_target_position(last_seen_position)

	if not nav_agent.is_navigation_finished():
		var destination = nav_agent.get_next_path_position()
		var local_destination = destination - global_position
		var direction = local_destination.normalized()

		velocity.x = direction.x * speedRun
		velocity.z = direction.z * speedRun

		print("[DEBUG] Moving toward:", destination, " | Direction:", direction)

		face_target(destination, delta)
	else:
		print("[DEBUG] Switching to patrol.")
		patrol(delta)

	move_and_slide()

func area_3d_in(body: Node3D) -> void:
	if body.is_in_group("pemain"):
		print("[DEBUG] Player entered detection zone.")
		area3d = true

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("pemain"):
		print("[DEBUG] Player exited detection zone.")
		area3d = false

func face_target(target_pos: Vector3, delta: float) -> void:
	var direction = (target_pos - global_position).normalized()
	direction.y = 0
	var current_angle = rotation.y
	var target_angle = atan2(direction.x, direction.z)
	rotation.y = lerp_angle(current_angle, target_angle, 5.0 * delta)

func patrol(delta: float) -> void:
	if point.is_empty():
		print("[DEBUG] Patrol points not set!")
		return

	if nav_agent.is_navigation_finished():
		var ranPatrol = randi_range(1, point.size() - 1)
		print("[DEBUG] New patrol point selected:", point[ranPatrol].global_transform.origin)
		nav_agent.set_target_position(point[ranPatrol].global_transform.origin)

	Global.destinationEnemy = nav_agent.get_next_path_position()
	var local_destination = Global.destinationEnemy - global_position
	var direction = local_destination.normalized()

	var target_pos = Global.destinationEnemy
	target_pos.y = global_position.y
	face_target(Global.destinationEnemy, delta)

	velocity.x = direction.x * speedWalk
	velocity.z = direction.z * speedWalk

	print("[DEBUG] Patrolling to:", Global.destinationEnemy, " | Direction:", direction)
