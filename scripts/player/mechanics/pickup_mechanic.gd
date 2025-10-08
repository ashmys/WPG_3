extends Node

# == NODE ==
@export var player: CharacterBody3D

func _pickup(target: Object) -> void:
	target.picked_up()
	print("player interact with ", target)
