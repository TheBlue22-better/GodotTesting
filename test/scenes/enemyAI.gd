extends CharacterBody3D

enum STATE {
	Passive,
	Guarding,
	Searching,
	Chasing,
	Attacking
}

@onready var navigation_agent_3d: NavigationAgent3D = $NavigationAgent3D

@export var GuardPoints: Array[Marker3D]
@export var Speed = 3.0

var currentState: STATE = STATE.Passive

func _ready() -> void:
	pass	
	
func _physics_process(delta: float) -> void:
	match currentState:
		STATE.Passive:
			navigation_agent_3d.set_target_position(GuardPoints.pick_random().global_position)
			changeState(STATE.Guarding)
		STATE.Guarding:
			if navigation_agent_3d.is_target_reached() == true:
				changeState(STATE.Passive)
			
			var destination = navigation_agent_3d.get_next_path_position()
			var local_destination = destination - global_position
			var direction = local_destination.normalized()
			
			velocity = direction * Speed
			move_and_slide()

func changeState(newState: STATE) -> void:
		currentState = newState
