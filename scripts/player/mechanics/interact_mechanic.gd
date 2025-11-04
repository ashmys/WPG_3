extends Node

# == NODE ==
@export var player: CharacterBody3D
@export var flashlight: Node3D

func _interact(target: Object) -> void:
	match target.object_name:
		"Refrigerator":
			if Global.gameStage == Global.State.PROLOG1:
				Global.gameStage = Global.State.PROLOG2
		"Microwave":
			if Global.gameStage == Global.State.PROLOG2:
				print("Masakan matang")
				Global.gameStage = Global.State.PROLOG3
		"Saklar":
			if Global.gameStage == Global.State.PROLOG4:
				print("Matikan")
				Global.lampu_mati += 1
			if Global.lampu_mati >= 2:
				Global.gameStage = Global.State.STAGE1
		"Battery":
			if Global.gameStage == Global.State.STAGE1:
				Global.battery_count += 1
				print(Global.battery_count)
				target.queue_free()
				if Global.battery_count >= 2:
					Global.gameStage = Global.State.STAGE2 
					flashlight.visible = true
		"Generator":
			if Global.gameStage == Global.State.STAGE3:
				Global.generator_on = true
		"Phone":
			if Global.gameStage == Global.State.STAGE4:
				if Global.generator_on:
					Global.call_police = true
		_:
			push_warning("object has no name(invalid)")
	
	print("player interact with ", target)
