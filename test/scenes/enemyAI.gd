extends CharacterBody3D

enum GUARD_STYLE {
	Random,
	Sequential,
	# Areal				#todo
}

enum STATE {
	Passive,
	Guarding,
	Searching,
	Chasing,
	Attacking
}

var GuardPointNum = 0
@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D
@onready var idle_timer: Timer = $IdleTimer

@export var GuardStyle: GUARD_STYLE = GUARD_STYLE.Random
@export var GuardPoints: Array[Marker3D]
@export var Speed = 3.0


var currentState: STATE = STATE.Passive
	
func _ready() -> void:
	changeState(STATE.Passive)
	
func _physics_process(delta: float) -> void:
	match currentState:
		STATE.Passive:
			pass
		STATE.Guarding:
			if navigation_agent_3d.is_target_reached() == true:
				changeState(STATE.Passive)
			var destination = navigation_agent_3d.get_next_path_position()
			var local_destination = destination - global_position
			var direction = local_destination.normalized()
			velocity = velocity.move_toward(direction * Speed, .5)
			var look_at_target:Vector3 = Vector3(destination.x,global_position.y,destination.z)
			if not global_position.is_equal_approx(look_at_target):
				look_at(look_at_target)
			
			
			
			move_and_slide()

func changeState(newState: STATE) -> void:
	currentState = newState
	match newState:
		STATE.Passive:
			nextGuardPosition()
			idle_timer.start(1 + randf())
	
func nextGuardPosition():
	if GuardStyle == GUARD_STYLE.Random:
		navigation_agent_3d.set_target_position(GuardPoints.pick_random().global_position)
	elif GuardStyle == GUARD_STYLE.Sequential:
		navigation_agent_3d.set_target_position(GuardPoints[GuardPointNum].global_position)
		GuardPointNum += 1
		if GuardPointNum >= GuardPoints.size():
			GuardPointNum = 0
		


func _on_idle_timer_timeout() -> void:
	changeState(STATE.Guarding)





func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		print("found player")
