extends Node3D

@export var light_array: Array[Node3D] = []
var all_lights_on: bool = true

func _ready() -> void:
	# Populate the light array when the scene starts
	light_array = get_all_nodes_3d(self)
	# Initialize with lights on
	toggle_all_lights()

# This function now toggles between on and off each time it's called
func toggle_all_lights() -> void:
	for light in light_array:
		if all_lights_on:
			if light.has_method("light_on"):
				light.light_on()
		else:
			if light.has_method("light_off"):
				light.light_off()
	all_lights_on = !all_lights_on

# Recursive function to collect all Node3D children that have light methods
func get_all_nodes_3d(root: Node) -> Array[Node3D]:
	var result: Array[Node3D] = []
	for child in root.get_children():
		if child is Node3D and (child.has_method("light_on") or child.has_method("light_off")):
			result.append(child)
		result.append_array(get_all_nodes_3d(child))
	return result
