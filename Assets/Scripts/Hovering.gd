extends State

@export var Player:CharacterBody3D
@export var ShipContainer:MeshInstance3D

var fallingPitchSpeed:float
var fallingPitchSpeedMax:float = 0.75
# Current speed
var forward_speed:float = 0.0
# Throttle input speed
var target_speed:float = 0.0
# Lets us disable certain things when grounded
var grounded = false

var turn_input:float = 0.0
var pitch_input:float = 0.0
var shipResource:StateMachine

func _ready():
	shipResource = get_parent()
	fallingPitchSpeed=shipResource.ShipStats.fallingPitchBase

func enter(oldState:String, flags:Dictionary):
	if flags.has("target_speed"):
		target_speed = flags.get("target_speed")
		Player.velocity = flags.get("Player.velocity")
		forward_speed = flags.get("forward_speed")

func physicsUpdate(delta:float):

	get_input(delta)
	# Rotate the transform based on the input values
	#Player.transform.basis = Player.transform.basis.rotated(Player.transform.basis.x, pitch_input * pitch_speed * delta)
	Player.transform.basis = Player.transform.basis.rotated(Vector3.UP, turn_input * shipResource.ShipStats.hovering_turn_speed * delta)

	# Roll the body based on the turn input
	ShipContainer.rotation.z = lerp(ShipContainer.rotation.z, turn_input*shipResource.ShipStats.hovering_rollMultiplier, shipResource.ShipStats.hovering_level_speed * delta)


	## Accelerate/decelerate
	forward_speed = lerp(forward_speed, target_speed, shipResource.ShipStats.hovering_acceleration * delta)

	# Movement is always forward
	Player.velocity = -Player.transform.basis.z * forward_speed

	if Player.is_on_floor():
		if not grounded:
			Player.rotation.x = 0
			fallingPitchSpeed = shipResource.ShipStats.fallingPitchBase
		Player.velocity.y -= 1
		grounded = true
		
		
		# Add a raycast here that checks the ground collision normals at 4 corners of the ship, and returns the average normal
		# which will be used automatically adjust the Player pitch, and shipcontainer roll
	else:
		grounded = false
		if Player.rotation.x > 0:
			Player.transform.basis = Player.transform.basis.rotated(Player.transform.basis.x,  -1.0 * fallingPitchSpeed * delta)
		elif Player.rotation.x > shipResource.ShipStats.fallingPitchMax:
			Player.transform.basis = Player.transform.basis.rotated(Player.transform.basis.x,  -1.0 * fallingPitchSpeed * delta)
			if fallingPitchSpeed < fallingPitchSpeedMax:
				fallingPitchSpeed += shipResource.ShipStats.fallingPitchBuildup*delta
	Player.move_and_slide()

func get_input(delta):
	if Input.is_action_just_pressed("swapMode"):
		var flags:Dictionary = {
		"target_speed":target_speed,
		"Player.velocity":Player.velocity,
		"forward_speed":forward_speed
		}
		finished.emit("Flying", flags)
	# Throttle input
	if Input.is_action_pressed("throttle_up"):
		target_speed = min(forward_speed + shipResource.ShipStats.hovering_throttle_delta * delta, shipResource.ShipStats.hovering_max_speed)
	if Input.is_action_pressed("throttle_down"):
		var limit = 0 if grounded else shipResource.ShipStats.hovering_min_speed
		target_speed = max(forward_speed - shipResource.ShipStats.hovering_throttle_delta * delta, limit)
	# Turn (roll/yaw) input
	turn_input = 0.0
	if forward_speed > 0.5:
		turn_input -= Input.get_action_strength("roll_right")
		turn_input += Input.get_action_strength("roll_left")
	# Pitch (climb/dive) input
	pitch_input = 0.0
	if not grounded:
		pitch_input -= Input.get_action_strength("pitch_down")
		pitch_input += Input.get_action_strength("pitch_up")
