extends Control

func _ready():
	visible = false
	Global.gameOver.connect(_on_player_caught)

func _on_player_caught():
	visible = true
	Global.gameStage = Global.State.END
	await get_tree().create_timer(2.0).timeout
	visible = false
	print("Switching scene now…")
	get_tree().call_deferred("change_scene_to_file", "res://scenes/main_menu.tscn")
	Global.battery_count = 0
	Global.generator_on = false
	Global.call_police = false
	Global.release_mouse()
