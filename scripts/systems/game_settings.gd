extends Panel

@export var audio_bus_names: Array[String] = ["Master", "Music", "SFX"]
var audio_bus_indices : Array[int] = []

func _ready() -> void:
	visible = false
	for bus_names in audio_bus_names:
		var idx = AudioServer.get_bus_index(bus_names)
		audio_bus_indices.append(idx)

func _on_fullscreen_control_toggled(toggled_on: bool) -> void:
	if toggled_on == true:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_FULLSCREEN)
	else:
		DisplayServer.window_set_mode(DisplayServer.WINDOW_MODE_WINDOWED)


func _on_music_slider_value_changed(value: float) -> void:
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(audio_bus_indices[1], db)


func _on_sfx_slider_value_changed(value: float) -> void:
	var db = linear_to_db(value)
	AudioServer.set_bus_volume_db(audio_bus_indices[2], db)

func _unhandled_input(_event: InputEvent) -> void:
	if Input.is_action_just_pressed("ui_cancel") and not Global.gameStage == Global.State.END:
		visible = not visible
		if visible:
			Global.release_mouse()
		else:
			Global.capture_mouse()

func _on_return_button_pressed() -> void:
	visible = false
	if visible:
		Global.release_mouse()
	else:
		Global.capture_mouse()

func _on_back_to_main_menu_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/main_menu.tscn")
