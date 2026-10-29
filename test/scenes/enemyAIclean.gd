extends CharacterBody3D

enum GUARD_STYLE {
	random,
	sequential
	#area
}

enum STATE {
	passive,
	guarding,
	chasing,
	searching,
	attacking
}

# exported external variables
@export_group("External")
@export var player: CharacterBody3D
@export var guardStyle: GUARD_STYLE = GUARD_STYLE.random
@export var guardPoints: Array[Marker3D]

# exported internal variables
@export_group("Internal")
@export var speed: float = 5.0

# external variables
@onready var navAgent: NavigationAgent3D = $NavigationAgent3D
@onready var idleTimer: Timer = $IdleTimer

# function bools
var navPointSet: bool = false
var passiveState: bool = false
var hasAttacked: bool = false
var playerInDetectionArea: bool = false
var playerDetected: bool = false

# internal variables
var currentState: STATE = STATE.passive
var currentGuardPoint: int = 0
var detection: float = 0

func _ready() -> void:
	pass
	
func _physics_process(delta: float) -> void:
	updateDetection()
	if player.debugLabel:
		updatePlayerDebug()
	match currentState:
		STATE.passive:
			passive_state()
		STATE.guarding:
			guard_state()
		STATE.chasing:
			chase_state()
		STATE.searching:
			search_state()
		STATE.attacking:
			attack_state()

func changeState(newState: STATE):
	currentState = newState
	
func updateDetection():
	pass
	
func updatePlayerDebug():
	player.setDebugAreaLabelText("Player in detection area: " + str(playerInDetectionArea))

func passive_state():
	if !passiveState:
		idleTimer.start(1+ randf())
		passiveState = true

func guard_state():
	if !navPointSet:
		setNextGuardPoint()
		navPointSet = true
	var destination = navAgent.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	velocity = velocity.move_toward(direction * speed, .5)
	var look_at_target:Vector3
	look_at_target = Vector3(destination.x,global_position.y,destination.z)
	if not global_position.is_equal_approx(look_at_target):
		look_at(look_at_target)
	
	move_and_slide()

func chase_state():
	pass

func search_state():
	pass

func attack_state():
	pass

func setNextGuardPoint():
	match guardStyle:
		GUARD_STYLE.random:
			navAgent.target_position = guardPoints.pick_random().global_position
		GUARD_STYLE.sequential:
			navAgent.target_position = guardPoints[currentGuardPoint].global_position
			if currentGuardPoint >= guardPoints.size(): currentGuardPoint = 0
				
			

func _on_navigation_agent_3d_navigation_finished() -> void:
	navPointSet = false
	match currentState:
		STATE.guarding:
			changeState(STATE.passive)
		STATE.chasing:
			changeState(STATE.attacking)


func _on_idle_timer_timeout() -> void:
	passiveState = false
	changeState(STATE.guarding)
	
	
func _on_detection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		playerInDetectionArea = true


func _on_detection_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		playerInDetectionArea = false
