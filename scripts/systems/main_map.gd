extends Node

const BALLOON_SCENE := preload("res://Assets/dialogue/balloon.tscn")

@export var dialogue_resource: DialogueResource

# Dialogue keys
@export_group("Dialogues")
@export var key_start: String = "start"
@export var key_prolog2: String = "kulkas"
@export var key_prolog3: String = "makan"
@export var key_prolog4: String = "tidur"
@export var key_stage1: String = "stage1"
@export var key_stage2: String = "stage2"
@export var key_stage3: String = "pembatas1"
@export var key_garage: String = "garage"

# References to nodes
@export_group("Nodes")
@export var bobby: CharacterBody3D
@export var valeria: CharacterBody3D
@export var player: CharacterBody3D
@export var taskbar_label: Label
@export var black_screen: Control
@export var black_screen_anim: AnimationPlayer
@export var area_barrier_stage1: Area3D

var _previous_stage := Global.gameStage
var _current_stage := Global.gameStage

func _ready() -> void:
	taskbar_label.text = "Go to the kitchen and eat"
	black_screen.visible = false
	bobby.is_active = false
	valeria.is_active = false
	_start_dialogue(key_start)
	Global.gameStage = Global.State.PROLOG1

func _process(_delta: float) -> void:
	_current_stage = Global.gameStage
	if _previous_stage == _current_stage:
		return

	match _current_stage:
		Global.State.PROLOG1:
			_enter_prolog1()
		Global.State.PROLOG2:
			_enter_prolog2()
		Global.State.PROLOG3:
			_enter_prolog3()
		Global.State.PROLOG4:
			_enter_prolog4()
		Global.State.STAGE1:
			_trigger_stage1()
		Global.State.STAGE2:
			_trigger_stage2()
		Global.State.STAGE3:
			_enter_stage3()
		_:
			pass

	_previous_stage = _current_stage

# Instantiates and starts a dialogue balloon
func _start_dialogue(key: String) -> void:
	var balloon = BALLOON_SCENE.instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(dialogue_resource, key)
	await balloon.dialogue_finished

func _enter_prolog1() -> void:
	bobby.is_active = false
	valeria.is_active = false

func _enter_prolog2() -> void:
	_start_dialogue(key_prolog2)

func _enter_prolog3() -> void:
	black_screen.visible = true
	_start_dialogue(key_prolog3)
	taskbar_label.text = "Go to the kitchen and eat ✓"
	await get_tree().create_timer(1.0).timeout
	taskbar_label.text = ""
	await get_tree().create_timer(1.0).timeout
	black_screen_anim.play("fade")
	await get_tree().create_timer(4.0).timeout
	black_screen.visible = false
	Global.gameStage = Global.State.PROLOG4

func _enter_prolog4() -> void:
	_start_dialogue(key_prolog4)
	taskbar_label.text = ""

func _trigger_stage1() -> void:
	area_barrier_stage1.global_position = Vector3(3.398, 3.106, -5.039)
	bobby.is_active = true
	_start_dialogue(key_stage1)

func _trigger_stage2() -> void:
	bobby.is_active = true
	$Area_pembatas1.global_position = Vector3(100, 100, 100)
	_start_dialogue(key_stage2)

func _enter_stage3() -> void:
	bobby.is_active = true
	valeria.is_active = true

func _on_trigger_stage_2_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and _current_stage == Global.State.STAGE1:
		_start_dialogue(key_garage)
