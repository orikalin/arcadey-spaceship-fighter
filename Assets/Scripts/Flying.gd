extends State

@export var Player:CharacterBody3D
@export var ShipContainer:MeshInstance3D

# Can't fly below this speed
@export var min_flight_speed = 5
# Maximum airspeed
@export var max_flight_speed = 50
# Turn rate
@export var turn_speed = 0.9
# Climb/dive rate
@export var pitch_speed = 0.75
# Wings "autolevel" speed
@export var level_speed = 3.0
# Throttle change speed
@export var throttle_delta = 50
# Acceleration/deceleration
@export var acceleration = 18.0
#roll strength
@export var rollMultiplier:float = 0.8

@export var rollCorrectionRate:float = 0.5

# Current speed
var forward_speed:float = 0.0
# Throttle input speed
var target_speed:float = 0.0
# Lets us disable certain things when grounded
var grounded = false

var turn_input:float = 0.0
var pitch_input:float = 0.0
var noPitchInputTimer:float = 0.0
var correctingRoll:bool = false


func enter(oldState:String, flags:Dictionary):
	if flags.has("target_speed"):
		target_speed = clamp(flags.get("target_speed"), 0, max_flight_speed)
		Player.velocity = flags.get("Player.velocity")
		forward_speed = flags.get("forward_speed")

func physicsUpdate(delta:float):
	get_input(delta)





	# Rotate the transform based on the input values
	Player.transform.basis = Player.transform.basis.rotated(Player.transform.basis.x, pitch_input * pitch_speed * delta)
	Player.transform.basis = Player.transform.basis.rotated(Vector3.UP, turn_input * turn_speed * delta)

	# Roll the body based on the turn input
	ShipContainer.rotation.z = lerp(ShipContainer.rotation.z, turn_input*0.8, level_speed * delta)

	# Accelerate/decelerate
	forward_speed = lerp(forward_speed, target_speed, acceleration * delta)

	# Movement is always forward
	Player.velocity = -Player.transform.basis.z * forward_speed
	Player.move_and_slide()



func get_input(delta):
	if Input.is_action_just_pressed("swapMode"):
		var flags:Dictionary = {
		"target_speed":target_speed,
		"Player.velocity":Player.velocity,
		"forward_speed":forward_speed
		}
		finished.emit("Hovering", flags)
	# Throttle input
	if Input.is_action_pressed("throttle_up"):
		target_speed = min(forward_speed + throttle_delta * delta, max_flight_speed)
	if Input.is_action_pressed("throttle_down"):
		var limit = 0 if grounded else min_flight_speed
		target_speed = max(forward_speed - throttle_delta * delta, limit)
	# Turn (roll/yaw) input
	turn_input = 0.0
	if forward_speed > 0.5:
		turn_input -= Input.get_action_strength("roll_right")
		turn_input += Input.get_action_strength("roll_left")
	# Pitch (climb/dive) input
	pitch_input = 0.0
	if forward_speed >= min_flight_speed:
		pitch_input -= Input.get_action_strength("pitch_down")
		pitch_input += Input.get_action_strength("pitch_up")
