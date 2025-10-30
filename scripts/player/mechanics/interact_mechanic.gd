extends Node

# == NODE ==
@export var player: CharacterBody3D
@export var flashlight: Node3D

func _interact(target: Object) -> void:
	match target.object_name:
		"Refrigerator":
			if Global.prolog:
				Global.food = true
		"Microwave":
			if Global.prolog and Global.food:
				print("Masakan matang")
				Global.cooked_food = true
		"Saklar":
			if Global.prolog2:
				print("Matikan")
				Global.lampu_mati += 1
			if Global.lampu_mati >= 2:
				Global.prolog2 = false
				Global.stage1 = true
		"Battery":
			if Global.stage1 == true:
				Global.battery_count += 1
				print(Global.battery_count)
				target.queue_free()
				if Global.battery_count >= 2:
					Global.stage2 = true
					flashlight.visible = true
		"Generator":
			if Global.stage3 == true:
				Global.generator_on = true
		"Phone":
			if Global.stage4 == true:
				if Global.generator_on:
					Global.call_police = true
		_:
			push_warning("object has no name(invalid)")
	
	print("player interact with ", target)
