extends Area3D

@export var chara: CharacterBody3D
@export var stair_lift_speed: float = 4.0

var on_stair: bool = false

func _physics_process(_delta: float) -> void:
	# Only consider stairs when the character is moving and on floor
	if chara.is_moving and chara.is_on_floor:
		# Assume no stair until we find one
		var found_stair = false
		for body in get_overlapping_bodies():
			if body.is_in_group("stairs"):
				found_stair = true
				break
		on_stair = found_stair
	else:
		on_stair = false

	if on_stair:
		# Gradually pull the character upward (or toward stair lift speed)
		chara.velocity.y += (stair_lift_speed - chara.velocity.y)
