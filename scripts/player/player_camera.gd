extends Node3D

# === Configuration ===
@export var mouse_sensitivity := 0.002
@export var auto_follow_sensitivity := 1.0
@export var arrow_sensitivity := 135
@export var turn_around_sensitivity := 10.0

@export_range(-90.0, 0.0, 0.1, "radians_as_degrees")
var min_vertical_angle: float = -PI / 2

@export_range(0.0, 90.0, 0.1, "radians_as_degrees")
var max_vertical_angle: float = PI / 4

# === Nodes ===
@export_group("Nodes")
@export var player: CharacterBody3D
@export var player_point : Node3D

# === Constants ===
const DEFAULT_PITCH := deg_to_rad(-25)
const DOUBLE_PRESS_INTERVAL := 0.3  # seconds

# === State ===
var mouse_captured := false
var look_rotation := Vector3.ZERO
var target_look_rotation := Vector3.ZERO
var mouse_idle_time := 0.0

# === Lifecycle ===
func _ready() -> void:
	_capture_mouse()

func _process(delta: float) -> void:
	if not mouse_captured:
		return

	_handle_arrow_input(delta)
	mouse_idle_time += delta

	_update_camera_transform()

func _unhandled_input(event: InputEvent) -> void:
	if Input.is_mouse_button_pressed(MOUSE_BUTTON_LEFT):
		_capture_mouse()
	elif Input.is_key_pressed(KEY_ESCAPE):
		_release_mouse()

	if mouse_captured and event is InputEventMouseMotion:
		_rotate_look(event.relative)
		mouse_idle_time = 0.0

# === Input Handlers ===
func _rotate_look(rot_input: Vector2) -> void:
	look_rotation.x = clamp(look_rotation.x - rot_input.y * mouse_sensitivity, min_vertical_angle, max_vertical_angle)
	look_rotation.y -= rot_input.x * mouse_sensitivity
	_update_camera_transform()

func _handle_arrow_input(delta: float) -> void:
	var yaw_input := int(Input.is_action_pressed("ui_left")) - int(Input.is_action_pressed("ui_right"))
	var pitch_input := int(Input.is_action_pressed("ui_up")) - int(Input.is_action_pressed("ui_down"))

	if yaw_input or pitch_input:
		mouse_idle_time = 0.0
		var rad_per_sec := deg_to_rad(arrow_sensitivity)
		look_rotation.y += yaw_input * rad_per_sec * delta
		look_rotation.x = clamp(look_rotation.x + pitch_input * rad_per_sec * delta, min_vertical_angle, max_vertical_angle)

# === Mouse Capture ===
func _capture_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	mouse_captured = true

func _release_mouse() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	mouse_captured = false

# === Utility ===
func _update_camera_transform() -> void:
	var x_rot := Basis(Vector3.RIGHT, look_rotation.x)
	var y_rot := Basis(Vector3.UP, look_rotation.y)
	transform.basis = y_rot * x_rot
