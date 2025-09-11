extends Control

@export var game_scene: PackedScene

@export var title: Label
@export var main_buttons: VBoxContainer
@export var settings: Panel
@export var credits: Panel

func _ready() -> void:
	show_main_menu()

func show_main_menu() -> void:
	title.visible = true
	main_buttons.visible = true
	settings.visible = false
	credits.visible = false

func _on_start_button_pressed() -> void:
	if game_scene:
		get_tree().change_scene_to_packed(game_scene)
	else:
		print("No game scene assigned.")

func _on_settings_button_pressed() -> void:
	title.visible = false
	main_buttons.visible = false
	settings.visible = true

func _on_credits_button_pressed() -> void:
	title.visible = false
	main_buttons.visible = false
	credits.visible = true

func _on_exit_button_pressed() -> void:
	get_tree().quit()

func _on_back_button_pressed() -> void:
	show_main_menu()
