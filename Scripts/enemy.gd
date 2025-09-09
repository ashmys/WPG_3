extends CharacterBody3D

var player: Node3D
const SPEED = 2.0
@export var player_path: NodePath
@export var fov_angle: float = 60.0   # Sudut pandang (derajat)
@export var view_distance: float = 10.0   # Jarak maksimum penglihatan

@onready var nav_agent = $NavigationAgent3D

func _ready() -> void:
	player = get_node(player_path)

func _physics_process(delta: float) -> void:
	velocity = Vector3.ZERO
	
	if can_see_player():
		nav_agent.set_target_position(player.global_position)
		var next_nav_point = nav_agent.get_next_path_position()
		velocity = (next_nav_point - global_position).normalized() * SPEED
		look_at(Vector3(next_nav_point.x, global_position.y, next_nav_point.z), Vector3.UP)
	
	move_and_slide()


func can_see_player() -> bool:
	# arah depan musuh
	var forward = -transform.basis.z.normalized()
	
	# vektor arah ke player
	var to_player = (player.global_position - global_position)
	var distance = to_player.length()
	if distance > view_distance:
		return false
	
	to_player = to_player.normalized()
	
	# cek sudut (dot product)
	var angle = rad_to_deg(acos(forward.dot(to_player)))
	if angle > fov_angle / 2.0:
		return false
	
	# cek line of sight (raycast manual)
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.create(global_position, player.global_position)
	var result = space_state.intersect_ray(query)
	
	if result.is_empty():
		return true
	elif result["collider"] == player:
		return true
	
	return false
