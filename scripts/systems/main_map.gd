extends Node

const Baloon = preload("res://Assets/dialogue/balloon.tscn")

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"
@export var dialogue_stage2: String = "stage2"
@export var dialogue_pembatas1: String = "pembatas1"
@export var dialogue_garage: String = "garage"
@export var e_bobby: CharacterBody3D
@export var e_valeria: CharacterBody3D
@export var player:CharacterBody3D

var stage2_triggered := false
var pengantar_stage2_triggerd:bool = false
var pembatas1_triggered := false

func _ready() -> void:
	var baloon = Baloon.instantiate()
	get_tree().current_scene.add_child(baloon)
	baloon.start(dialogue_resource, dialogue_start)

func _process(delta: float) -> void:
	if not Global.stage1:
		e_bobby.set_physics_process(false)
		e_bobby.set_process(false)
		e_valeria.set_physics_process(false)
		e_valeria.set_process(false)
		e_valeria.visible = false
	
	if Global.stage1:
		e_bobby.set_physics_process(true)
		e_bobby.set_process(true)
		e_valeria.set_physics_process(false)
		e_valeria.set_process(false)
		e_valeria.visible = false

	if Global.stage2 and not stage2_triggered:
		$pembatas1.global_position = Vector3(100,100,100)
		stage2_triggered = true
		var baloon = Baloon.instantiate()
		get_tree().current_scene.add_child(baloon)
		baloon.start(dialogue_resource, dialogue_stage2)
	
	if Global.stage3:
		e_bobby.set_physics_process(true)
		e_bobby.set_process(true)
		e_valeria.set_physics_process(true)
		e_valeria.set_process(true)
		e_valeria.visible = true

func _on_area_3d_pembatas_1() -> void:
	if not pembatas1_triggered:
		print("Masuk area pembatas 1")
		pembatas1_triggered = true
		var baloon = Baloon.instantiate()
		get_tree().current_scene.add_child(baloon)
		baloon.start(dialogue_resource, dialogue_pembatas1)


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body is CharacterBody3D and not pengantar_stage2_triggerd:
		pengantar_stage2_triggerd = true
		var baloon = Baloon.instantiate()
		get_tree().current_scene.add_child(baloon)
		baloon.start(dialogue_resource, dialogue_garage)
		

func _on_area_3d_body_exited(body: Node3D) -> void:
	if body is CharacterBody3D:
		Global.stage1 = true
