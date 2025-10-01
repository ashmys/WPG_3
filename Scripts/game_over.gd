extends Control

func _ready():
	visible = false

func _on_player_caught():
	visible = true
	get_tree().paused = true
