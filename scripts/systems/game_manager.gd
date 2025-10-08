extends Node

@export var game_scene: PackedScene
@export var timer: Timer
@export var timerText: Label
@export var game_winUI: Control

var has_started: bool = false

func _physics_process(_delta: float) -> void:
	if Global.battery_count >= 2 and !has_started:
		timer.start()
		has_started = true
		
	var tl = timer.time_left
	timerText.text = str(tl)

func _on_timer_timeout() -> void:
	game_winUI.visible = true
	await get_tree().create_timer(2.0).timeout
	get_tree().unload_current_scene()
