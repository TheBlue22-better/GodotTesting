extends CanvasLayer

@onready var player_detection: Label = $ControlDebug/PlayerDetection
@onready var player_in_detection_area: Label = $ControlDebug/PlayerInDetectionArea
@onready var player: CharacterBody3D = $".."
@onready var control_debug: Control = $ControlDebug
@onready var health_bar: TextureProgressBar = $ControlMain/HealthBar
@onready var debug_string: Label = $ControlDebug/DebugString
@onready var sus_meter: Label = $ControlDebug/susMeter

func _ready() -> void:
	
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	if player.debugLabel:
		control_debug.show()
		player_in_detection_area.text = "Player in detection area: " + str(player.playerInDetectionArea)
		player_detection.text = "Detection: " + str(player.playerDetection)
		debug_string.text = player.debugString
		sus_meter.text = "sus= " + str(player.susMeter)
	else: control_debug.hide()
	health_bar.value = player.health
