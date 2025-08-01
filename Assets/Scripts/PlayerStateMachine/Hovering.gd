extends State

@export var Player:CharacterBody3D
@export var ShipContainer:MeshInstance3D
@export var floor_raycast:RayCast3D
@export var falling_damping_curve:Curve

var fallingPitchSpeed:float
# Current speed
var forward_speed:float = 0.0
# Throttle input speed
var target_speed:float = 0.0
# Lets us disable certain things when grounded
var grounded = false

var turn_input:float = 0.0
var pitch_input:float = 0.0
var ship_statemachine:StateMachine

signal camera_Y_offset()

func _ready():
	ship_statemachine = get_parent()
	fallingPitchSpeed=ship_statemachine.ship_stats.fallingPitchBase

func enter(oldState:String, flags:Dictionary):
	if flags.has("firstTime"): 
		return
	elif oldState == "Flying" or "Drift":
		target_speed = flags.get("target_speed")
		Player.velocity = flags.get("Player.velocity")
		forward_speed = flags.get("forward_speed")

func physicsUpdate(delta:float):
	get_input(delta)
	# Rotate the transform based on the input values
	#Player.transform.basis = Player.transform.basis.rotated(Player.transform.basis.x, pitch_input * pitch_speed * delta)
	Player.transform.basis = Player.transform.basis.rotated(Vector3.UP, turn_input * ship_statemachine.ship_stats.hovering_turn_speed * delta)

	# Roll the body based on the turn input
	ShipContainer.rotation.z = lerp(ShipContainer.rotation.z, turn_input*ship_statemachine.ship_stats.hovering_rollMultiplier, ship_statemachine.ship_stats.hovering_level_speed * delta)

	## Accelerate/decelerate
	forward_speed = lerp(forward_speed, target_speed, ship_statemachine.ship_stats.hovering_acceleration * delta)

	# Movement is always forward
	Player.velocity = -Player.transform.basis.z * forward_speed

	if Player.is_on_floor():
		if not grounded:
			#Player.rotation.x = 0
			fallingPitchSpeed = ship_statemachine.ship_stats.fallingPitchBase
		Player.velocity.y -= 1
		grounded = true
		
		
		# Add a raycast here that checks the ground collision normals at 4 corners of the ship, and returns the average normal
		# which will be used automatically adjust the Player pitch, and shipcontainer roll
	else:
		grounded = false
		if Player.rotation.x > 0:
			Player.transform.basis = Player.transform.basis.rotated(Player.transform.basis.x,  -1.0 * fallingPitchSpeed * delta)
		elif Player.rotation.x > ship_statemachine.ship_stats.fallingPitchMax:
			var _remap_range = Helpers.Map(Player.rotation.x, 0, ship_statemachine.ship_stats.fallingPitchMax, 0, 1)
			var curve_sample:float = falling_damping_curve.sample(_remap_range)
			Player.transform.basis = Player.transform.basis.rotated(Player.transform.basis.x,  -1.0 * fallingPitchSpeed * delta * curve_sample)
			if fallingPitchSpeed < ship_statemachine.ship_stats.fallingPitchSpeedMax:
				fallingPitchSpeed += ship_statemachine.ship_stats.fallingPitchBuildup*delta
	offset_camera_Y(delta)
	Player.move_and_slide()

	if grounded:
		align_to_floor_normal(delta, false)

		


func align_to_floor_normal(delta, instant:bool):
	var floor_normal = floor_raycast.get_collision_normal()
	var target_normal_local = floor_normal * Player.basis
	var target_pitch = atan2(target_normal_local.z, target_normal_local.y)
	if not instant:
		Player.transform.basis = Player.transform.basis.rotated(Player.transform.basis.x, target_pitch * ship_statemachine.ship_stats.slerp_speed * delta)
	else:
		Player.transform.basis = Player.transform.basis.rotated(Player.transform.basis.x, target_pitch)

func align_with_y(xform, new_y):
	xform.y = new_y
	xform.x = -xform.z.cross(new_y)
	xform = xform.orthonormalized()
	return xform

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
		target_speed = min(forward_speed + ship_statemachine.ship_stats.hovering_throttle_delta * delta, ship_statemachine.ship_stats.hovering_max_speed)
	if Input.is_action_pressed("throttle_down"):
		var limit = 0 if grounded else ship_statemachine.ship_stats.hovering_min_speed
		target_speed = max(forward_speed - ship_statemachine.ship_stats.hovering_throttle_delta * delta, limit)
	# Turn (roll/yaw) input
	turn_input = 0.0
	turn_input -= Input.get_action_strength("roll_right")
	turn_input += Input.get_action_strength("roll_left")
	# Pitch (climb/dive) input
	pitch_input = 0.0
	if not grounded:
		pitch_input -= Input.get_action_strength("pitch_down")
		pitch_input += Input.get_action_strength("pitch_up")
	# Drift input
	if grounded:
		if Input.is_action_pressed("drift"):
			if Input.is_action_pressed("roll_left") or Input.is_action_pressed("roll_right"):
				var flags:Dictionary = {
					"target_speed":target_speed,
					"Player.velocity":Player.velocity,
					"forward_speed":forward_speed,
					"Player.basis":Player.basis
				}
				align_to_floor_normal(delta, true)
				finished.emit("Drift", flags)


func offset_camera_Y(delta:float):
	var _normalized_forward_speed = Helpers.Map(forward_speed, 0, ship_statemachine.ship_stats.hovering_max_speed, 0, 1)
	var targetY = Helpers.Map(_normalized_forward_speed, 0, 1, 0, ship_statemachine.ship_stats.camera_Y_offset)
	camera_Y_offset.emit(_normalized_forward_speed, targetY, delta)
