extends StaticBody3D

# == CONFIG ==
@export var hide_marker: Marker3D
@export var sfx_name: String

func play_object_sfx():
	AudioManager.play_sfx(sfx_name)
	
