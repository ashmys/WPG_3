extends AudioStreamPlayer3D


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("pemain"):
		play()
		Global.sound = true
		Global.source = global_position
