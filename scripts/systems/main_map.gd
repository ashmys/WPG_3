extends Node

const Baloon = preload("res://Assets/dialogue/balloon.tscn")

@export var dialogue_resource: DialogueResource
@export var dialogue_start: String = "start"

func _ready() -> void:
	var baloon: Node = Baloon.instantiate()
	get_tree().current_scene.add_child(baloon)
	baloon.start(dialogue_resource, dialogue_start)
