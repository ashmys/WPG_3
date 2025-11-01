extends Node3D

@export var bulb_mesh : MeshInstance3D
@export var omnilight : OmniLight3D

func _ready() -> void:
	light_on()

func light_on() -> void:
	var material = bulb_mesh.mesh.surface_get_material(0)
	if material and material is StandardMaterial3D:
		material.emission_enabled = true
	omnilight.visible = true

func light_off() -> void:
	var material = bulb_mesh.mesh.surface_get_material(0)
	if material and material is StandardMaterial3D:
		material.emission_enabled = false
	omnilight.visible = false
