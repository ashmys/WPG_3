extends Node

const Baloon = preload("res://Assets/dialogue/balloon.tscn")

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"
@export var dialogue_kulkas: String = "kulkas"
@export var dialogue_makan: String = "makan"
@export var dialogue_matikanLampu: String = "matikanLampu"
@export var dialogue_stage1: String = "stage1"
@export var dialogue_stage2: String = "stage2"
@export var dialogue_pembatas1: String = "pembatas1"
@export var dialogue_garage: String = "garage"
@export var e_bobby: CharacterBody3D
@export var e_valeria: CharacterBody3D
@export var player:CharacterBody3D
@export var taskbar:Label
@export var blackScreen:Control
@export var blackScreenAnim:AnimationPlayer
@export var pembatasAreaStage1:Area3D

var prolog2_triggered:= false
var stage1_triggered := false
var stage2_triggered := false
var kulkas_triggered := false
var makan_triggered := false
var pengantar_stage2_triggerd:bool = false
var pembatas1_triggered := false

func _ready() -> void:
	var baloon = Baloon.instantiate()
	get_tree().current_scene.add_child(baloon)
	baloon.start(dialogue_resource, dialogue_start)
	await baloon.dialogue_finished
	taskbar.text = "Go to the kitchen and eat"
	blackScreen.visible = false

func _process(delta: float) -> void:
	if Global.prolog:
		e_bobby.set_physics_process(false)
		e_bobby.set_process(false)
		e_bobby.visible = false
		e_valeria.set_physics_process(false)
		e_valeria.set_process(false)
		e_valeria.visible = false

		
	if Global.prolog and Global.food and not kulkas_triggered:
		kulkas_triggered = true
		var baloon = Baloon.instantiate()
		get_tree().current_scene.add_child(baloon)
		baloon.start(dialogue_resource, dialogue_kulkas)
		e_bobby.set_physics_process(false)
		e_bobby.set_process(false)
		e_bobby.visible = false
		e_valeria.set_physics_process(false)
		e_valeria.set_process(false)
		e_valeria.visible = false
		
	if Global.prolog and Global.food and Global.cooked_food and not makan_triggered:
		blackScreen.visible = true
		e_bobby.set_physics_process(false)
		e_bobby.set_process(false)
		e_bobby.visible = false
		e_valeria.set_physics_process(false)
		e_valeria.set_process(false)
		e_valeria.visible = false
		makan_triggered = true
		var baloon = Baloon.instantiate()
		get_tree().current_scene.add_child(baloon)
		baloon.start(dialogue_resource, dialogue_makan)
		await baloon.dialogue_finished
		taskbar.text = "Go to the kitchen and eat ✓"
		await get_tree().create_timer(1.0).timeout
		taskbar.text = ""
		await get_tree().create_timer(1.0).timeout
		blackScreenAnim.play("fade")
		await get_tree().create_timer(4.0).timeout
		blackScreen.visible = false
		Global.prolog = false
		Global.prolog2 = true
		
	
	if Global.prolog2 and not prolog2_triggered:
		prolog2_triggered = true
		
		#Enemy controller
		e_bobby.set_physics_process(false)
		e_bobby.set_process(false)
		e_bobby.visible = false
		e_valeria.set_physics_process(false)
		e_valeria.set_process(false)
		e_valeria.visible = false
		
		var baloon = Baloon.instantiate()
		get_tree().current_scene.add_child(baloon)
		baloon.start(dialogue_resource, dialogue_matikanLampu)
		await baloon.dialogue_finished
		taskbar.text = ""


	
	if Global.stage1 and not stage1_triggered:
		stage1_triggered = true
		pembatasAreaStage1.global_position = Vector3(3.398,3.106,-5.039)
		e_bobby.set_physics_process(true)
		e_bobby.set_process(true)
		e_valeria.set_process(false)
		e_valeria.visible = false
		var baloon = Baloon.instantiate()
		get_tree().current_scene.add_child(baloon)
		baloon.start(dialogue_resource, dialogue_stage1)

	if Global.stage2 and not stage2_triggered:
		e_bobby.visible = true
		$Area_pembatas1.global_position = Vector3(100,100,100)
		stage2_triggered = true
		var baloon = Baloon.instantiate()
		get_tree().current_scene.add_child(baloon)
		baloon.start(dialogue_resource, dialogue_stage2)

func _on_area_3d_pembatas_1() -> void:
	if not pembatas1_triggered:
		print("Masuk area pembatas 1")
		pembatas1_triggered = true
		var baloon = Baloon.instantiate()
		get_tree().current_scene.add_child(baloon)
		baloon.start(dialogue_resource, dialogue_pembatas1)


func _on_area_3d_body_entered(body: Node3D) -> void:
	if Global.stage1:
		if body is CharacterBody3D and not pengantar_stage2_triggerd:
			pengantar_stage2_triggerd = true
			var baloon = Baloon.instantiate()
			get_tree().current_scene.add_child(baloon)
			baloon.start(dialogue_resource, dialogue_garage)
			await  baloon.dialogue_finished
			e_bobby.set_physics_process(true)
			e_bobby.set_process(true)
		

func _on_area_3d_body_exited(body: Node3D) -> void:
	if Global.stage1:
		if body is CharacterBody3D:
			Global.stage1 = true

func _on_area_pembatas_1_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and not pengantar_stage2_triggerd:
		pengantar_stage2_triggerd = true
		var baloon = Baloon.instantiate()
		get_tree().current_scene.add_child(baloon)
		baloon.start(dialogue_resource, dialogue_pembatas1)


func _on_area_pembatas_1_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D and pengantar_stage2_triggerd:
		pengantar_stage2_triggerd = false
