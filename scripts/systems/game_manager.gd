extends Node

@export var scene_path: String
@export var timer: Timer
@export var game_Win_UI: Control
@export var other_UI: Control
@export var light_group: Node3D

var has_started: bool = false

func _physics_process(_delta: float) -> void:
	if Global.call_police and !has_started:
		timer.start()
		has_started = true

	if Global.generator_on:
		light_group.visible =  true

func _on_timer_timeout() -> void:
	other_UI.visible = false
	game_Win_UI.visible = true
	await get_tree().create_timer(2.0).timeout
	if scene_path:
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		Global.call_police = false
		Global.gameStage = Global.State.END
		get_tree().change_scene_to_file(scene_path)
	else:
		push_warning("scene_path is null")
