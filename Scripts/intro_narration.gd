extends Control

@export var anim : AnimationPlayer
@export var game_scene: PackedScene

func _ready() -> void:
	animation()

func animation():
	await get_tree().create_timer(1.0).timeout
	$"1".visible = true
	anim.play("type")
	await get_tree().create_timer(20.0).timeout
	$"1".visible = false
	$"2".visible = true
	anim.play("2")
	await get_tree().create_timer(20.0).timeout
	$"2".visible = false
	$"3".visible = true
	anim.play("3")
	await get_tree().create_timer(20.0).timeout
	$"3".visible = false
	$"4".visible = true
	anim.play("4")
	await get_tree().create_timer(15.0).timeout
	$"4".visible = false
	$"5".visible = true
	await get_tree().create_timer(3.0).timeout
	get_tree().change_scene_to_packed(game_scene)
