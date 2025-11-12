extends Node

## The body this component is attached to (e.g. player or NPC)
@export var parent_body_path: NodePath
@onready var parent_body: CharacterBody3D = get_node_or_null(parent_body_path)

## Approximate "mass" of this body (in kg)
@export var approx_mass: float = 80.0

## Minimum mass ratio for pushing (ignore very heavy objects)
@export var min_mass_ratio: float = 0.25

## Push strength multiplier
@export var push_multiplier: float = 5.0

## Ignore vertical push components (horizontal only)
@export var flatten_push_y: bool = true

## Use central impulse when near center of mass (faster)
@export var use_central_impulse: bool = true


func _ready() -> void:
	if parent_body == null:
		push_error("PushAwayRigidBodies: parent_body_path not set or invalid.")


func apply_push_forces() -> void:
	if parent_body == null:
		return

	var my_velocity: Vector3 = parent_body.velocity
	var collision_count: int = parent_body.get_slide_collision_count()

	for i in collision_count:
		var collision: KinematicCollision3D = parent_body.get_slide_collision(i)
		var collider: Object = collision.get_collider()

		if collider is RigidBody3D:
			var push_dir: Vector3 = -collision.get_normal()

			if flatten_push_y:
				push_dir.y = 0.0

			if push_dir == Vector3.ZERO:
				continue

			var rigid: RigidBody3D = collider

			var rel_vel: float = my_velocity.dot(push_dir) - rigid.linear_velocity.dot(push_dir)
			if rel_vel <= 0.0:
				continue

			var mass_ratio: float = approx_mass / rigid.mass
			if mass_ratio < min_mass_ratio:
				continue
			if mass_ratio > 1.0:
				mass_ratio = 1.0

			var impulse_strength: float = rel_vel * (mass_ratio * push_multiplier)
			var impulse: Vector3 = push_dir * impulse_strength
			var offset: Vector3 = collision.get_position() - rigid.global_position

			if use_central_impulse and offset.length_squared() < 0.04:
				rigid.apply_central_impulse(impulse)
			else:
				rigid.apply_impulse(impulse, offset)
