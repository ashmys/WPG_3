extends StaticBody3D

# == CONFIG ==
@export var object_name: String
@export var sfx_name: String
@export var saklarID: int

func play_object_sfx():
	AudioManager.play_sfx(sfx_name)
