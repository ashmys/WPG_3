extends Node3D

@onready var camera = 0
@onready var maxCamera = 4
@onready var enemy = false
@onready var enemyMuncul 

func _ready():
	$Camera3D.global_transform.origin = Vector3(0,1,3.5)
	$Camera3D.rotation_degrees = Vector3(10, -90, 0)
	$flashlight_btn.visible = false
	

func _on_timer_timeout() -> void:
	$ProgressBar.value -= 1


func _on_button_pressed() -> void:
	$Button.visible = false
	$">_button".visible = true
	$"<_button".visible = true
	$X_button.visible = true
	$flashlight_btn.visible = true
	camera = 1


func _on__button_left_pressed() -> void:
	if camera + 1 == maxCamera + 1:
		camera = 1
	else :
		camera += 1


func _on_x_button_pressed() -> void:
	camera = 0
	$Button.visible = true
	$">_button".visible = false
	$"<_button".visible = false
	$X_button.visible = false
	$flashlight_btn.visible = false


func _on__button_right_pressed() -> void:
	if camera - 1 == 0:
		camera = maxCamera
	else :
		camera -= 1
	
func _process(delta: float) -> void:
	if camera == 0:
		$Camera3D.global_transform.origin = Vector3(0,1,3.5)
		$Camera3D.rotation_degrees = Vector3(10, -90, 0)
	elif camera == 1:
		$Camera3D.global_transform.origin = Vector3(-1,3,-3)
		$Camera3D.rotation_degrees = Vector3(-20, -50, 0)
	elif camera == 2 :
		$Camera3D.global_transform.origin = Vector3(14,4,9)
		$Camera3D.rotation_degrees = Vector3(-25,50,0)
	elif camera == 3 :
		$Camera3D.global_transform.origin = Vector3(9,8,9)
		$Camera3D.rotation_degrees = Vector3(-10,30,0)
	elif camera == 4 :
		$Camera3D.global_transform.origin = Vector3(9.5,8.5,-7)
		$Camera3D.rotation_degrees = Vector3(-10,90,0)
	
	

func _on_flashlight_btn_button_up() -> void:
	$Camera3D/flashlight.visible = false
	if enemy == true:
		if camera == enemyMuncul:
			enemy = false
	


func _on_flashlight_btn_button_down() -> void:
	$Camera3D/flashlight.visible = true


func _on_enemy_timer_timeout() -> void:
	enemyMuncul = randi_range(0,9)
	if enemyMuncul >= 0 and enemyMuncul <=4:
		enemy = true
		
		$enemy.visible = true
		
		if enemyMuncul == 2:
			$enemy.global_transform.origin = Vector3(11.5,0,5.5)
			$enemy.rotation_degrees = Vector3(0,45,0)
		elif enemyMuncul == 1: 
			$enemy.global_transform.origin = Vector3(7,0.5,-10)
			$enemy.rotation_degrees = Vector3(0,-45,0)
		elif enemyMuncul == 4: 
			$enemy.global_transform.origin = Vector3(0,5,-7)
			$enemy.rotation_degrees = Vector3(0,90,0)
		elif enemyMuncul == 3:
			$enemy.global_transform.origin = Vector3(7.003,5.088,6.499)
			$enemy.rotation_degrees = Vector3(-10,43.3,0)
	else:
		enemy = false

func _on_flashlight_btn_pressed() -> void:
	pass
	
