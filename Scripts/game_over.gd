extends Control

func _ready():
	visible = false

func _on_player_caught():
	visible = true
	get_tree().paused = true
	Global.battery_count = 0
	Global.stage1 = false
	Global.stage2 = false
