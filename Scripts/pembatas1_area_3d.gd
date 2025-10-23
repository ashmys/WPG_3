extends Area3D

const Baloon = preload("res://Assets/dialogue/balloon.tscn")
@export var dialogue_resource: DialogueResource
@export var dialogue_pembatas1: String = "pembatas1"

var player_entered:bool = false

signal pembatas1

func _on_body_entered(body: Node3D) -> void:
		pembatas1.emit()


func _on_body_exited(body: Node3D) -> void:
	if body.is_in_group("player"):
		player_entered = false
