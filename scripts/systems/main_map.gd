extends Node

const Baloon = preload("res://Assets/dialogue/balloon.tscn")

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"
@export var e_bobby: CharacterBody3D
@export var e_valeria: CharacterBody3D

var stage1:bool = false



func _ready() -> void:
	var baloon: Node = Baloon.instantiate()
	get_tree().current_scene.add_child(baloon)
	baloon.start(dialogue_resource, dialogue_start)

func _process(delta: float) -> void:
	if stage1 == false:
		e_bobby.set_physics_process(false)
		e_bobby.set_process(false)
