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
@export var searchRadius: int = 5
@export var attackDistance: float = 1.5
@export var attackCooldown: int = 2
@export var damage: int = 10

# external variables
@onready var navAgent: NavigationAgent3D = $NavigationAgent3D
@onready var idleTimer: Timer = $IdleTimer
@onready var attack_timer: Timer = $AttackTimer

# function bools
var attackOnCooldown: bool = false
var navPointSet: bool = false
var idleTimeRunning: bool = false
var hasAttacked: bool = false
var playerInDetectionArea: bool = false
var playerDetected: bool = false
var searchPointReached: bool = false

# internal variables
var currentState: STATE = STATE.passive
var currentGuardPoint: int = 0
var detection: float = 0
var susMeter: float = 0
var searchPoints: Array[Vector3]
var numOfSearchPoints: int = 0

func _ready() -> void:
	player.connect("sound_created_sneak", player_sneak_sound)
	player.connect("sound_created_sprint", player_sprint_sound)
	player.connect("sound_created_walk", player_walk_sound)
	
func _physics_process(delta: float) -> void:
	updateDetection()
	updateSusMeter()
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
	if detection >= 100 and currentState != STATE.attacking:
			changeState(STATE.chasing)
	if playerDetected:
		if detection <= 100:
			detection += 1
			player.playerDetection += 1
	else:
		if detection >= 0:
			detection -= 0.1
			player.playerDetection -= 0.1
			
func updateSusMeter():
	if susMeter >= 100 and ((currentState != STATE.chasing) or (currentState != STATE.attacking)):
		begin_search(player.global_position)
		changeState(STATE.searching)
	if susMeter > 100: 
		susMeter = 100
		player.susMeter = 100
	if susMeter < 0: 
		susMeter = 0
		player.susMeter = 0
	susMeter -= 0.01
	player.susMeter -= 0.01


func passive_state():
	if !idleTimeRunning:
		idleTimer.start(1 + randf())
		idleTimeRunning = true

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
	if global_position.distance_to(navAgent.target_position) <= attackDistance:
		changeState(STATE.attacking)
	navAgent.target_position = player.global_position
	var destination = navAgent.get_next_path_position()
	var local_destination = destination - global_position
	var direction = local_destination.normalized()
	velocity = velocity.move_toward(direction * speed, .5)
	var look_at_target:Vector3
	look_at_target = Vector3(destination.x,global_position.y,destination.z)
	if not global_position.is_equal_approx(look_at_target):
		look_at(look_at_target)
		
	move_and_slide()

func search_state():
	if searchPointReached:
		navAgent.target_position = searchPoints[numOfSearchPoints - 1]
		numOfSearchPoints -= 1
		searchPointReached = false
	if numOfSearchPoints == 0:
		changeState(STATE.passive)
	else:
		var destination = navAgent.get_next_path_position()
		var local_destination = destination - global_position
		var direction = local_destination.normalized()
		velocity = velocity.move_toward(direction * speed, .5)
		var look_at_target:Vector3
		look_at_target = Vector3(destination.x,global_position.y,destination.z)
		if not global_position.is_equal_approx(look_at_target):
			look_at(look_at_target)
		move_and_slide()
		
func get_search_points(numOfPoints: int, initialPoint: Vector3):
	for n in numOfPoints:
		var randomAngle = randf() * TAU
		var offset = Vector3(cos(randomAngle) * searchRadius, initialPoint.y, sin(randomAngle) * searchRadius)
		var targetPoint = initialPoint + offset
		
		searchPoints.append(NavigationServer3D.map_get_closest_point(get_world_3d().navigation_map,targetPoint))

func begin_search(lastPos: Vector3):
	navAgent.target_position = lastPos
	numOfSearchPoints = randi_range(5,9)
	get_search_points(numOfSearchPoints, lastPos)

func attack_state():
	player.debugString = "attacking"
	if global_position.distance_to(player.global_position) > attackDistance:
		changeState(STATE.chasing)
	if !attackOnCooldown:
		attackPlayer()
		attack_timer.start(attackCooldown)
		attackOnCooldown = true

func attackPlayer():
	player.take_damage(10)

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
		STATE.searching:
			searchPointReached = true


func _on_idle_timer_timeout() -> void:
	idleTimeRunning = false
	changeState(STATE.guarding)
	
	
func _on_detection_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		playerInDetectionArea = true
		player.playerInDetectionArea = true


func _on_detection_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		playerInDetectionArea = false
		player.playerInDetectionArea = false
		if currentState == STATE.chasing: 
			begin_search(body.global_position)
			changeState(STATE.searching)

func player_sneak_sound():
	if global_position.distance_to(player.global_position) <= 2:
		player.susMeter += 10
		susMeter += 10
		player.debugString = "player is sneaking and i hear it"
	player.debugString = "player is sneaking"

func player_sprint_sound():
	if global_position.distance_to(player.global_position) <= 15:
		player.susMeter += 10
		susMeter += 10
		player.debugString = "player is sprinting and i hear it"
	player.debugString = "player is sprinting"
	
func player_walk_sound():
	if global_position.distance_to(player.global_position) <= 8:
		player.susMeter += 10
		susMeter += 10
		player.debugString = "player is walking and i hear it"
	player.debugString = "player is walking"

func _on_vision_area_body_entered(body: Node3D) -> void:
	if body.is_in_group("Player"):
		playerDetected = true


func _on_vision_area_body_exited(body: Node3D) -> void:
	if body.is_in_group("Player"):
		playerDetected = false
		


func _on_attack_timer_timeout() -> void:
	attackOnCooldown = false
