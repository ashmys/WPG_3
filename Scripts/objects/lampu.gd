extends Node3D

@export var bulb_mesh_on : MeshInstance3D
@export var omnilight : OmniLight3D
@export var is_on: bool = true

func _ready() -> void:
	light_on()

func light_on() -> void:
	bulb_mesh_on.visible = true
	omnilight.visible = true
	is_on = true

func light_off() -> void:
	bulb_mesh_on.visible = false
	omnilight.visible = false
	is_on = false
