extends Node

const BALLOON_SCENE := preload("res://Assets/dialogue/balloon.tscn")

@export var dialogue_resource: DialogueResource

# Dialogue keys
@export_group("Dialogues")
@export var key_start: String = "start"
@export var key_fridge: String = "kulkas"
@export var key_eat: String = "makan"
@export var key_turn_off_light: String = "matikanLampu"
@export var key_stage1: String = "stage1"
@export var key_stage2: String = "stage2"
@export var key_barrier1: String = "pembatas1"
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
@export var light: Node3D

var _previous_stage := Global.gameStage
var _current_stage := Global.gameStage

func _ready() -> void:
	_enemy_logic(bobby,false)
	_enemy_logic(valeria,false)
	await _start_dialogue(key_start)
	_enter_prolog1()

func _process(_delta: float) -> void:
	_current_stage = Global.gameStage
	if _previous_stage == _current_stage:
		return

	match _current_stage:
		Global.State.PROLOG1:
			print("Prolog 1")
			_enter_prolog1()
		Global.State.PROLOG2:
			print("Prolog 2")
			_trigger_fridge_dialogue()
		Global.State.PROLOG3:
			print("Prolog 3")
			_trigger_eat_dialogue()
		Global.State.PROLOG4:
			print("Prolog 4")
			_enter_prolog4()
		Global.State.STAGE1:
			print("Stage 1")
			_trigger_stage1()
		Global.State.STAGE2:
			print("Stage 2")
			_trigger_stage2()
		Global.State.STAGE3:
			print("Stage 3")
			_enter_stage3()
		_:
			pass

	_previous_stage = _current_stage

# Instantiates and starts a dialogue balloon
func _start_dialogue(key: String) -> void:
	player.set_physics_process(false)
	var balloon = BALLOON_SCENE.instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(dialogue_resource, key)
	await balloon.dialogue_finished
	player.set_physics_process(true)

func _enter_prolog1() -> void:
	taskbar_label.text = "Go to the kitchen and eat"
	black_screen.visible = false
	_enemy_visible(bobby,valeria,false)

func _trigger_fridge_dialogue() -> void:
	await _start_dialogue(key_fridge)

func _trigger_eat_dialogue() -> void:
	black_screen.visible = true
	await _start_dialogue(key_eat)
	taskbar_label.text = "Go to the kitchen and eat ✓"
	await get_tree().create_timer(1.0).timeout
	taskbar_label.text = ""
	await get_tree().create_timer(1.0).timeout
	black_screen_anim.play("fade")
	await get_tree().create_timer(4.0).timeout
	black_screen.visible = false
	Global.gameStage = Global.State.PROLOG4

func _enter_prolog4() -> void:
	await _start_dialogue(key_turn_off_light)
	taskbar_label.text = "Turn Off the Light on the house"

func _trigger_stage1() -> void:
	area_barrier_stage1.global_position = Vector3(3.398, 3.106, -5.039)
	light.visible = false
	_enemy_visible(bobby,valeria,false)
	await _start_dialogue(key_stage1)
	taskbar_label.text = "Find 2 Battery"

func _trigger_stage2() -> void:
	taskbar_label.text = "Find Battery " + str(Global.battery_count) + "/2 ✓"
	await get_tree().create_timer(1.0).timeout
	_enemy_visible(bobby,null, true)
	$Area_pembatas1.global_position = Vector3(100, 100, 100)
	await _start_dialogue(key_stage2)

func _enter_stage3() -> void:
	# If you only want this to run once, add a guard flag
	taskbar_label.text = "Find a way to active the electricity"
	await get_tree().create_timer(5.0).timeout
	print("Enemy Active")
	_enemy_logic(bobby,true)

func _enemy_visible(gender1: CharacterBody3D, gender2: CharacterBody3D = null, visible: bool = true) -> void:
	gender1.visible = visible
	if gender2:
		gender2.visible = visible

func _enemy_logic(enemy: CharacterBody3D, active:bool)-> void:
	enemy.set_physics_process(active)
	enemy.set_process(active)

# Area signals
func _on_area_3d_pembatas_1_entered() -> void:
	await _start_dialogue(key_barrier1)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and Global.gameStage == Global.State.STAGE2:
		await _start_dialogue(key_garage)
		$trigger_stage2.global_position = Vector3(5.492, -10, 6.971)
		Global.gameStage = Global.State.STAGE3

func _on_area_barrier1_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and Global.gameStage == Global.State.STAGE1:
		await _start_dialogue(key_barrier1)
