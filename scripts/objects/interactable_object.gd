extends StaticBody3D

# == CONFIG ==
@export var object_name: String
@export var sfx_name: String
@export var saklarID: int
@export var collider: CollisionShape3D

var _is_active: bool = true

func play_object_sfx():
	AudioManager.play_sfx(sfx_name)

func toggle_active():
	_is_active = !_is_active
	visible = !visible
	collider.disabled = !collider.disabled
	
