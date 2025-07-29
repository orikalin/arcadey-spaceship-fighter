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
var ship_resource:StateMachine

func _ready():
	ship_resource = get_parent()
	fallingPitchSpeed=ship_resource.ShipStats.fallingPitchBase

func enter(oldState:String, flags:Dictionary):
	if flags.has("target_speed"):
		target_speed = flags.get("target_speed")
		Player.velocity = flags.get("Player.velocity")
		forward_speed = flags.get("forward_speed")

func physicsUpdate(delta:float):

	get_input(delta)
	# Rotate the transform based on the input values
	#Player.transform.basis = Player.transform.basis.rotated(Player.transform.basis.x, pitch_input * pitch_speed * delta)
	Player.transform.basis = Player.transform.basis.rotated(Vector3.UP, turn_input * ship_resource.ShipStats.hovering_turn_speed * delta)

	# Roll the body based on the turn input
	ShipContainer.rotation.z = lerp(ShipContainer.rotation.z, turn_input*ship_resource.ShipStats.hovering_rollMultiplier, ship_resource.ShipStats.hovering_level_speed * delta)


	## Accelerate/decelerate
	forward_speed = lerp(forward_speed, target_speed, ship_resource.ShipStats.hovering_acceleration * delta)

	# Movement is always forward
	Player.velocity = -Player.transform.basis.z * forward_speed

	if Player.is_on_floor():
		if not grounded:
			#Player.rotation.x = 0
			fallingPitchSpeed = ship_resource.ShipStats.fallingPitchBase
		Player.velocity.y -= 1
		grounded = true
		
		
		# Add a raycast here that checks the ground collision normals at 4 corners of the ship, and returns the average normal
		# which will be used automatically adjust the Player pitch, and shipcontainer roll
	else:
		grounded = false
		if Player.rotation.x > 0:
			Player.transform.basis = Player.transform.basis.rotated(Player.transform.basis.x,  -1.0 * fallingPitchSpeed * delta)
		elif Player.rotation.x > ship_resource.ShipStats.fallingPitchMax:
			var _remap_range = Helpers.Map(Player.rotation.x, 0, ship_resource.ShipStats.fallingPitchMax, 0, 1)
			var curve_sample:float = falling_damping_curve.sample(_remap_range)
			Player.transform.basis = Player.transform.basis.rotated(Player.transform.basis.x,  -1.0 * fallingPitchSpeed * delta * curve_sample)
			if fallingPitchSpeed < ship_resource.ShipStats.fallingPitchSpeedMax:
				fallingPitchSpeed += ship_resource.ShipStats.fallingPitchBuildup*delta
	Player.move_and_slide()

	if grounded:
		var floor_normal = floor_raycast.get_collision_normal()
		# # var slopeLean:Vector3 = Vector3(slope_normal.x, 0.0, slope_normal.z)
		# # var target_basis = align_with_y(Player.basis, slope_normal)
		# # var player_basis = Player.basis.orthonormalized()
		# # Player.basis = player_basis.slerp(target_basis, slerp_speed*delta)
		# var target_basis:Basis = Basis()
		# target_basis.x = slope_normal.cross(Player.basis.z).normalized()
		# target_basis.y = slope_normal
		# target_basis.z = Player.basis.x.cross(target_basis.y)
		# var current_rotation:Quaternion = Quaternion(Player.basis.orthonormalized())
		# var target_rotation:Quaternion = Quaternion(target_basis.orthonormalized())
		# Player.basis = current_rotation.slerp(target_rotation, slerp_speed * delta)
		var target_normal_local = floor_normal * Player.basis
		var target_pitch = atan2(target_normal_local.z, target_normal_local.y)
		Player.transform.basis = Player.transform.basis.rotated(Player.transform.basis.x, target_pitch * ship_resource.ShipStats.slerp_speed * delta)




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
		target_speed = min(forward_speed + ship_resource.ShipStats.hovering_throttle_delta * delta, ship_resource.ShipStats.hovering_max_speed)
	if Input.is_action_pressed("throttle_down"):
		var limit = 0 if grounded else ship_resource.ShipStats.hovering_min_speed
		target_speed = max(forward_speed - ship_resource.ShipStats.hovering_throttle_delta * delta, limit)
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
