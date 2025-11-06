extends AnimationTree

@export var player: CharacterBody3D
@export var head: Node3D

# == VAR ==
enum State {RESET,IDLE,WALK,RUN}
var curAnim := State.RESET
var idle_cooldown := 1.0

func _physics_process(_delta: float) -> void:
	if player.is_moving:
		if not player.is_sprint:
			curAnim = State.WALK
		else:
			curAnim = State.RUN
	else:
		if head.mouse_idle_time >= idle_cooldown:
			curAnim = State.IDLE
		else:
			curAnim = State.RESET
	
	match curAnim:
		State.RESET:
			set("parameters/Movement/transition_request","RESET")
		State.IDLE:
			set("parameters/Movement/transition_request","Idle")
		State.WALK:
			set("parameters/Movement/transition_request","Walk")
		State.RUN:
			set("parameters/Movement/transition_request","Run")
