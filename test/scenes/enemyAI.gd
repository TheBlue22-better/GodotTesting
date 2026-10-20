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
@export var debug_label_area: Label3D
@export var debug_label_detection: Label3D
@export var player: CharacterBody3D


var currentState: STATE = STATE.Passive
var playerInDetectionArea: bool = false
var playerInVisionArea: bool = false
var playerDetection: float = 0.0
var playerLastKnownPosition
	
func _ready() -> void:
	changeState(STATE.Passive)
	updateDebugLabels()
	
func _physics_process(delta: float) -> void:
	updateDebugLabels()
	updatePlayerDetection()
	match currentState:
		STATE.Passive:
			pass
		STATE.Guarding:
			guardState()
		STATE.Chasing:
			chaseState()
			

func changeState(newState: STATE) -> void:
	currentState = newState
	print(str(newState))
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

func updateDebugLabels():
	debug_label_area.text = "Player detected: " + str(playerInDetectionArea)
	debug_label_detection.text = "Detection: " + str(playerDetection)

func updatePlayerDetection():
	if playerInDetectionArea:
		if playerInVisionArea and playerDetection <= 100: playerDetection += 1
		if playerDetection >= 100:
			if currentState != STATE.Chasing:
				changeState(STATE.Chasing)
	if playerDetection != 0 and !playerInVisionArea: playerDetection -= 0.1
	if playerDetection < 0: playerDetection = 0
	
func guardState():
	if navigation_agent_3d.is_target_reached() == true:
		changeState(STATE.Passive)
	var destination = navigation_agent_3d.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	velocity = velocity.move_toward(direction * Speed, .5)
	var look_at_target:Vector3
	if playerInDetectionArea and playerDetection > 0:
		look_at_target = Vector3(player.global_position.x,global_position.y,player.global_position.z)
	else:
		look_at_target = Vector3(destination.x,global_position.y,destination.z)
	if not global_position.is_equal_approx(look_at_target):
		look_at(look_at_target)
	
	move_and_slide()
		
func chaseState():
	if navigation_agent_3d.is_target_reached():
			changeState(STATE.Passive)
	if playerInDetectionArea:
		navigation_agent_3d.target_position = player.global_position
	else:
		navigation_agent_3d.target_position = playerLastKnownPosition
		
	var destination = navigation_agent_3d.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	velocity = velocity.move_toward(direction * Speed, .5)
	var look_at_target = Vector3(player.global_position.x,global_position.y,player.global_position.z)
	if not global_position.is_equal_approx(look_at_target):
		look_at(look_at_target)
	move_and_slide()


func _on_idle_timer_timeout() -> void:
	changeState(STATE.Guarding)


func _on_area_3d_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		playerInDetectionArea = true


func _on_detection_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		playerInDetectionArea = false
	if currentState == STATE.Chasing and body.is_in_group("Player"):
		playerLastKnownPosition = Vector3(body.global_position.x, global_position.y, body.global_position.z)


func _on_vision_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		playerInVisionArea = true


func _on_vision_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		playerInVisionArea = false
