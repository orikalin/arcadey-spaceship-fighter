extends State

@export var Player:CharacterBody3D
@export var proxy:CharacterBody3D
@export var ShipContainer:MeshInstance3D
@export var floor_raycast:RayCast3D
@export var falling_damping_curve:Curve
# @export var player_collision_shapes:Array
# @export var proxy_collision_shapes:Array

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
	fallingPitchSpeed=ship_resource.ship_stats.fallingPitchBase

func enter(oldState:String, flags:Dictionary):
	if oldState == "Hovering":
		proxy.transform = Player.transform
		toggle_collision_shapes()
		target_speed = flags.get("target_speed")
		forward_speed = flags.get("forward_speed")
		proxy.velocity = flags.get("Player.velocity")
		

func physicsUpdate(delta:float):

	get_input(delta)
	# Rotate the transform based on the input values
	#Player.transform.basis = Player.transform.basis.rotated(Player.transform.basis.x, pitch_input * pitch_speed * delta)
	Player.transform.basis = Player.transform.basis.rotated(Vector3.UP, turn_input * ship_resource.ship_stats.drift_turn_speed * delta)
	

	# Roll the body based on the turn input
	ShipContainer.rotation.z = lerp(ShipContainer.rotation.z, turn_input*ship_resource.ship_stats.hovering_rollMultiplier*2, ship_resource.ship_stats.hovering_level_speed * delta)


	## Accelerate/decelerate
	forward_speed = lerp(forward_speed, target_speed, ship_resource.ship_stats.hovering_acceleration * delta)

	# Movement is always forward
	proxy.velocity = -proxy.transform.basis.z * forward_speed #add drifting speed decay

	if proxy.is_on_floor():
		if not grounded:
			#Player.rotation.x = 0
			fallingPitchSpeed = ship_resource.ship_stats.fallingPitchBase
		proxy.velocity.y -= 1
		grounded = true
		var angle = Player.basis.z.signed_angle_to(proxy.basis.z, -Player.basis.y) # get the different in angle
		proxy.transform.basis = proxy.transform.basis.rotated(Vector3.UP, angle * ship_resource.ship_stats.drift_proxy_turn_speed * delta) 
		
		# Add a raycast here that checks the ground collision normals at 4 corners of the ship, and returns the average normal
		# which will be used automatically adjust the Player pitch, and shipcontainer roll
	else:
		grounded = false
		if proxy.rotation.x > 0:
			proxy.transform.basis = proxy.transform.basis.rotated(proxy.transform.basis.x,  -1.0 * fallingPitchSpeed * delta)
		elif proxy.rotation.x > ship_resource.ship_stats.fallingPitchMax:
			var _remap_range = Helpers.Map(proxy.rotation.x, 0, ship_resource.ship_stats.fallingPitchMax, 0, 1)
			var curve_sample:float = falling_damping_curve.sample(_remap_range)
			proxy.transform.basis = proxy.transform.basis.rotated(proxy.transform.basis.x,  -1.0 * fallingPitchSpeed * delta * curve_sample)
			if fallingPitchSpeed < ship_resource.ship_stats.fallingPitchSpeedMax:
				fallingPitchSpeed += ship_resource.ship_stats.fallingPitchBuildup*delta
	proxy.move_and_slide()
	Player.position = proxy.position

	if grounded:
		align_to_floor_normal(delta, false)


func align_to_floor_normal(delta, instant:bool):
	var floor_normal = floor_raycast.get_collision_normal()
	var target_normal_local = floor_normal * proxy.basis
	var target_pitch = atan2(target_normal_local.z, target_normal_local.y)
	if not instant:
		proxy.transform.basis = proxy.transform.basis.rotated(proxy.transform.basis.x, target_pitch * ship_resource.ship_stats.slerp_speed * delta)
	else:
		proxy.transform.basis = proxy.transform.basis.rotated(proxy.transform.basis.x, target_pitch)

func get_input(delta):
	if multiplayer.multiplayer_peer != null and not owner.network_id ==  multiplayer.get_unique_id():
		return
	# Throttle input
	# if Input.is_action_pressed("throttle_up"):
	# 	target_speed = min(forward_speed + ship_resource.ship_stats.hovering_throttle_delta * delta, ship_resource.ship_stats.hovering_max_speed)
	# if Input.is_action_pressed("throttle_down"):
	# 	var limit = 0 if grounded else ship_resource.ship_stats.hovering_min_speed
	# 	target_speed = max(forward_speed - ship_resource.ship_stats.hovering_throttle_delta * delta, limit)
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
	if not Input.is_action_pressed("drift"):
		var flags:Dictionary = {
		"target_speed":target_speed,
		"Player.velocity":proxy.velocity,
		"forward_speed":forward_speed
		}
		toggle_collision_shapes()
		finished.emit("Hovering", flags)

func toggle_collision_shapes():
	var player_collision_shapes:Array = Array()
	player_collision_shapes.append(%Player/ShipCollider)
	player_collision_shapes.append(%Player/GroundedRayCollider)
	var proxy_collision_shapes:Array = Array()
	proxy_collision_shapes.append(%PlayerProxy/ShipCollider)
	player_collision_shapes.append(%PlayerProxy/GroundedRayCollider)
	for shapes in player_collision_shapes:
		shapes.disabled = not shapes.disabled
	for shapes in proxy_collision_shapes:
		shapes.disabled = not shapes.disabled
	
