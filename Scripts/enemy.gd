extends CharacterBody3D

const GRAVITY = 9.8

@onready var nav_agent: NavigationAgent3D = $NavigationAgent3D
@onready var view = $Area3D
@onready var hear = $AudioListener3D

@export var point:Array[Marker3D]
@export var player : CharacterBody3D
@export var speedRun: int = 5
@export var speedWalk: int = 5

enum State { PATROL, CHASE, SEARCH }
var state: State = State.PATROL
var area3d:bool = false
var last_seen_position: Vector3 = Vector3.ZERO
var last_seen_time: float = -1.0
var chase_memory: float = 2.0

func _physics_process(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta
	
	if Global.sound == true:
		nav_agent.set_target_position(Global.source)
		var destination = nav_agent.get_next_path_position()
		var local_destination = destination - global_position
		var direction = local_destination.normalized()
		
		var target_pos = destination
		target_pos.y = global_position.y
		face_target(destination, delta)
		
		if nav_agent.is_navigation_finished():
			Global.sound = false
			return
	
	if not player:
		return
	
	var space: PhysicsDirectSpaceState3D = get_world_3d().direct_space_state
	var from = global_transform.origin + Vector3.UP * 1.0
	var to = player.global_transform.origin + Vector3.UP * 1.0
	
	var query := PhysicsRayQueryParameters3D.create(from, to)
	query.exclude = [self]
	
	var result: Dictionary = space.intersect_ray(query)
	
	if result and (result.collider == player or result.collider.get_parent() == player):
		if area3d:
			Global.sound = false
			last_seen_position = player.global_transform.origin
			last_seen_time = Time.get_ticks_msec() / 1000.0  # simpan waktu dalam detik
			nav_agent.set_target_position(last_seen_position)
	

	elif last_seen_time > 0 and (Time.get_ticks_msec() / 1000.0 - last_seen_time < chase_memory):
		nav_agent.set_target_position(last_seen_position)
	

	if nav_agent.is_navigation_finished() == false:
		var destination = nav_agent.get_next_path_position()
		var local_destination = destination - global_position
		var direction = local_destination.normalized()
		
		velocity.x = direction.x * speedRun
		velocity.z = direction.z * speedRun
		
		face_target(destination, delta)
	else:
		patrol(delta)
	
	move_and_slide()

func area_3d_in(body: Node3D) -> void:
	if body.is_in_group("pemain"):
		print("In my zone")
		area3d = true


func _on_area_3d_body_exited(body: Node3D) -> void:
	if body.is_in_group("pemain"):
		print("Out my zone")
		area3d = false
	
func face_target(target_pos: Vector3, delta: float) -> void:
	var direction = (target_pos - global_position).normalized()
	direction.y = 0  # biar cuma muter di sumbu Y
	
	var current_angle = rotation.y
	var target_angle = atan2(direction.x, direction.z)
	
	# 5.0 = kecepatan rotasi, bisa kamu ubah
	rotation.y = lerp_angle(current_angle, target_angle, 5.0 * delta)

func patrol(delta: float) -> void:
	if point.is_empty():
		return
	
	if nav_agent.is_navigation_finished():
		var ranPatrol = randi_range(1,point.size()-1)
		nav_agent.set_target_position(point[ranPatrol].global_transform.origin)
	

	Global.destinationEnemy = nav_agent.get_next_path_position()
	var local_destination = Global.destinationEnemy - global_position
	var direction = local_destination.normalized()
	
	#menghadap tujuan
	var target_pos = Global.destinationEnemy
	target_pos.y = global_position.y
	face_target(Global.destinationEnemy, delta)

	
	velocity.x = direction.x * speedWalk
	velocity.z = direction.z * speedWalk
