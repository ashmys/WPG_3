extends Node

# == NODE ==
@export var player: CharacterBody3D

func _pickup(target: Object) -> void:
	match target.object_name:
		"battery":
			if target.object_name == "battery":
				Global.battery_count += 1
				print(Global.battery_count)
				target.queue_free()
		_:
			push_warning("object has no name(invalid)")
	
	print("player interact with ", target)
