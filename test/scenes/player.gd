extends CharacterBody3D

var input_direction : Vector2
var speed : float

enum MOVEMENT_MODE {
	sneaking,
	walking,
	sprinting
}

@export var look_sensitivity: float = 0.005
@export var walk_speed = 5.0
@export var sprint_speed = 10.0
@export var sneak_speed = 2.0
@export var acceleration = 60.0
@export var jump_velocity = 4.5
@export var air_control = 5.0
@export var air_resistance = 2.0

@export var debugLabel: bool = true
@export var playerInDetectionArea: bool = false
@export var playerDetection: float = 0
@export var susMeter: float = 0
@export var health: int = 100


signal sound_created_sneak
signal sound_created_walk
signal sound_created_sprint

var debugString: String = "test"
var movement: MOVEMENT_MODE

@onready var head = $Head
@onready var camera = $Head/Camera3D



func _ready():
	Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _unhandled_input(event):
	if event is InputEventMouseMotion and Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
		head.rotate_y(-event.relative.x * look_sensitivity)
		camera.rotate_x(-event.relative.y * look_sensitivity)
		camera.rotation.x = clamp(camera.rotation.x, deg_to_rad(-80), deg_to_rad(80))

	if Input.is_action_just_pressed("escape"):
		Input.mouse_mode = Input.MOUSE_MODE_VISIBLE

	if event is InputEventMouseButton and event.pressed:
		Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _physics_process(delta):
	# Apply gravity when in the air
	if not is_on_floor():
		velocity += get_gravity() * delta

	# Handle Sprint
	if Input.is_action_pressed("sprint") and is_on_floor():
		speed = sprint_speed
		movement = MOVEMENT_MODE.sprinting
	elif Input.is_action_pressed("sneak"):
		speed = sneak_speed
		movement = MOVEMENT_MODE.sneaking
	else:
		speed = walk_speed
		movement = MOVEMENT_MODE.walking
	
	# Handle jump
	if Input.is_action_just_pressed("jump") and is_on_floor():
		velocity.y = jump_velocity

	# Get direction input
	input_direction = Input.get_vector("left", "right", "up", "down")
	var direction = (head.transform.basis * Vector3(input_direction.x, 0, input_direction.y)).normalized()
	
	# Calculate movement
	var target_velocity = direction * speed
	var horizontal_velocity = Vector3(velocity.x, 0, velocity.z)

	if is_on_floor():
		# Ground movement
		horizontal_velocity = horizontal_velocity.move_toward(target_velocity, acceleration * delta)
		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.z
	else:
		# Air movement
		if direction:
			horizontal_velocity = horizontal_velocity.move_toward(target_velocity, air_control * delta)
		
		horizontal_velocity = horizontal_velocity.move_toward(Vector3.ZERO, air_resistance * delta)
		velocity.x = horizontal_velocity.x
		velocity.z = horizontal_velocity.z
	
	move_and_slide()

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("down") or event.is_action_pressed("left") or event.is_action_pressed("up") or event.is_action("right"):
		match movement:
			MOVEMENT_MODE.walking:
				sound_created_walk.emit()
			MOVEMENT_MODE.sprinting:
				sound_created_sprint.emit()
			MOVEMENT_MODE.sneaking:
				sound_created_sneak.emit()

func take_damage(damage: int):
	debugString = "took " + str(damage) + " damage"
	health -= damage
