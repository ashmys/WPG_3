extends StaticBody3D

# == CONFIG ==
@export var sfx_name: String

func play_object_sfx():
	AudioManager.play_sfx(sfx_name)

func picked_up():
	Global.battery_count += 1
	print(Global.battery_count)
	queue_free()
