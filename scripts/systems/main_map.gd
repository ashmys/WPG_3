extends Node

const BALLOON_SCENE := preload("res://Assets/dialogue/balloon.tscn")

@export var dialogue_resource: DialogueResource

# Dialogue keys
@export_group("Dialogues")
@export var key_start: String = "start"
@export var key_prolog2: String = "prolog2"
@export var key_prolog3: String = "prolog3"
@export var key_prolog4: String = "prolog4"
@export var key_stage1: String = "stage1"
@export var key_stage2: String = "stage2"
@export var key_stage3: String = "pembatas1"
@export var key_garage: String = "stage3"

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
@export var lampuID : Array[Node3D]
@export var hp_table:StaticBody3D
@export var prolog3Position: Marker3D

var _previous_stage := Global.gameStage
var _current_stage := Global.gameStage

var balloon

func _ready() -> void:
	Global.saklar.connect(_saklar)
	black_screen.visible = false
	bobby.is_active = false
	valeria.is_active = false
	await _start_dialogue(key_start)
	Global.gameStage = Global.State.PROLOG1

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
			_enter_prolog2()
		Global.State.PROLOG3:
			print("Prolog 3")
			_enter_prolog3()
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
		Global.State.STAGE4:
			print("Stage 4")
			_enter_stage4()
		Global.State.STAGE5:
			print("Stage 5")
			_enter_stage5()
			hp_table.visible = true
		Global.State.STAGE6:
			print("Stage 6")
			_enter_stage5()
		_:
			pass

	_previous_stage = _current_stage

# Instantiates and starts a dialogue balloon
func _start_dialogue(key: String) -> void:
	player.can_move = false
	balloon = BALLOON_SCENE.instantiate()
	get_tree().current_scene.add_child(balloon)
	balloon.start(dialogue_resource, key)
	await balloon.dialogue_finished
	player.can_move = true

func _enter_prolog1() -> void:
	taskbar_label.text = "Go to the kitchen and eat"
	black_screen.visible = false
	bobby.is_active = false

func _enter_prolog2() -> void:
	_start_dialogue(key_prolog2)

func _enter_prolog3() -> void:
	player.can_move = false
	black_screen.visible = true
	_start_dialogue(key_prolog3)
	taskbar_label.text = "Go to the kitchen and eat ✓"
	await get_tree().create_timer(1.0).timeout
	taskbar_label.text = ""
	await get_tree().create_timer(1.0).timeout
	black_screen_anim.play("fade")
	await get_tree().create_timer(4.0).timeout
	player.global_position = prolog3Position.global_position
	player.rotation.y = 90
	player.rotation.x = 0
	player.rotation.z = 0
	black_screen.visible = false
	player.can_move = true
	Global.gameStage = Global.State.PROLOG4

func _enter_prolog4() -> void:
	await _start_dialogue(key_prolog4)
	taskbar_label.text = "Turn off lights and go to bed"

func _trigger_stage1() -> void:
	taskbar_label.text = "Turn off lights and go to bed"
	area_barrier_stage1.global_position = Vector3(3.398, 3.106, -5.039)
	light.visible = false
	await _start_dialogue(key_stage1)
	taskbar_label.text = "I need to find 2 Battery"

func _trigger_stage2() -> void:
	taskbar_label.text = "2 Battery found"
	await get_tree().create_timer(1.0).timeout
	taskbar_label.text = "Check Garage"
	$Area_pembatas1.global_position = Vector3(100, 100, 100)
	await _start_dialogue(key_stage2)
	bobby.is_active = true
	bobby.can_move = false

func _enter_stage3() -> void:
	await _start_dialogue(key_garage)
	$trigger_stage2.global_position = Vector3(5.492, -10, 6.971)
	taskbar_label.text = "Run and Hide!"
	print("Bobby is Active")
	bobby.can_move = true

func _enter_stage4() -> void:
	taskbar_label.text = "Find a way to turn on the lights"

func _enter_stage5() -> void:
	valeria.is_active = true
	valeria.can_move = false
	taskbar_label.text = "Hide again!"
	await get_tree().create_timer(0.5).timeout
	print("Valeria is Active too")
	valeria.can_move = true

func _enter_stage6() -> void:
	taskbar_label.text = "Survive until Police arrive"

# Area signals
func _on_area_3d_pembatas_1_entered() -> void:
	await _start_dialogue(key_stage1)

func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and Global.gameStage == Global.State.STAGE2:
		Global.gameStage = Global.State.STAGE3

func _on_area_barrier1_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and Global.gameStage == Global.State.STAGE1:
		await _start_dialogue(key_stage2)
		
func _saklar(saklarID: int) -> void:
	if saklarID >= 0 and saklarID < lampuID.size():
		var lamp = lampuID[saklarID]
		if lamp.is_on:
			_lampu_off(saklarID)
		else:
			_lampu_on(saklarID)

func _lampu_on(saklarID: int):
	if saklarID >= 0 and saklarID < lampuID.size():
		lampuID[saklarID].light_on()

func _lampu_off(saklarID: int):
	if saklarID >= 0 and saklarID < lampuID.size():
		lampuID[saklarID].light_off()


func _on_trigger_stage_1_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and Global.gameStage == Global.State.PROLOG4:
		Global.gameStage = Global.State.STAGE1
