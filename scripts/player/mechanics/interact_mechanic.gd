extends Node

# == NODE ==
@export var player: CharacterBody3D
@export var flashlight: Node3D

func _interact(target: Object) -> void:
	match target.object_name:
		"Battery":
			Global.battery_count += 1
			print(Global.battery_count)
			target.queue_free()
			if Global.battery_count >= 2:
				flashlight.visible = true
		"Generator":
			Global.generator_on = true
		"Phone":
			if Global.generator_on:
				Global.call_police = true
		_:
			push_warning("object has no name(invalid)")
	
	print("player interact with ", target)
