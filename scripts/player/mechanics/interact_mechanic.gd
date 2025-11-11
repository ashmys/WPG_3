extends Node

# == NODE ==
@export var player: CharacterBody3D
@export var piring: Node3D
@export var senter: Node3D
@export var flashlight: Node3D

func _interact(target: Object) -> void:
	match target.object_name:
		"Refrigerator":
			if Global.gameStage == Global.State.PROLOG1:
				piring.visible = true
				Global.gameStage = Global.State.PROLOG2
		"Microwave":
			if Global.gameStage == Global.State.PROLOG2:
				Global.gameStage = Global.State.PROLOG3
				await get_tree().create_timer(5.0).timeout
				piring.visible = false
		"Saklar":
			if Global.gameStage == Global.State.PROLOG4:
				Global.emit_signal("saklar", target.saklarID)
				Global.lampu_mati += 1
			if Global.lampu_mati >= 11:
				Global.gameStage = Global.State.STAGE1
				senter.visible = true
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
		"cas_hp":
			if Global.gameStage == Global.State.STAGE4:
				if Global.generator_on:
					Global.gameStage = Global.State.STAGE5
		_:
			push_warning("object has no name(invalid)")
	
	print("player interact with ", target)
