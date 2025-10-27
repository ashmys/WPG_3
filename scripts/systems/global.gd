extends Node

var battery_count : int = 0
var generator_on : bool = false
var call_police : bool = false


var prolog:bool = true
var stage1:bool = false
var stage2:bool = false
var stage3:bool = false


var sound:bool = false
var source:Vector3

var destinationEnemy

func goto_scene(path: String) -> void:
	_deferred_goto_scene.call_deferred(path)


func _deferred_goto_scene(path: String) -> void:
	get_tree().current_scene.free()

	var packed_scene: PackedScene = ResourceLoader.load(path)

	var instanced_scene := packed_scene.instantiate()

	# Add it to the scene tree, as direct child of root
	get_tree().root.add_child(instanced_scene)

	# Set it as the current scene, only after it has been added to the tree
	get_tree().current_scene = instanced_scene
