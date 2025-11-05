extends Node

var mouse_captured := false

var battery_count : int = 0
var generator_on : bool = false
var call_police : bool = false

enum State {PROLOG1,PROLOG2,PROLOG3,PROLOG4,STAGE1,STAGE2,STAGE3,STAGE4,STAGE5,END}
var gameStage := State.PROLOG1

var sound:bool = false
var source:Vector3

var destinationEnemy

# === Mouse Capture ===
func capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

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
