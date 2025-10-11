extends AnimationTree

@export var player: CharacterBody3D
@export var head: Node3D

# == VAR ==
enum {RESET,IDLE,WALK,RUN}
var curAnim := RESET
var idle_cooldown := 1.0

func _physics_process(_delta: float) -> void:
	if player.is_moving:
		if not player.is_sprint:
			curAnim = WALK
		else:
			curAnim = RUN
	else:
		if head.mouse_idle_time >= idle_cooldown:
			curAnim = IDLE
		else:
			curAnim = RESET
	
	match curAnim:
		RESET:
			set("parameters/Movement/transition_request","RESET")
		IDLE:
			set("parameters/Movement/transition_request","Idle")
		WALK:
			set("parameters/Movement/transition_request","Walk")
		RUN:
			set("parameters/Movement/transition_request","Run")
