extends State

@export var player:CharacterBody3D
@export var proxy_xform:CharacterBody3D
@export var proxy_orb:RigidBody3D
@export var ShipContainer:MeshInstance3D
@export var StickCurve:Curve
@export var accel_force:float = 180.0
@export var turn_force:float = 9.0 
@export var turn_stop_limit:float
@export var rolling_level_speed:float = 5.0
@export var gravity_airborne:float = 4.0
@export var gravity_grounded:float = 0.2
@export var ground_stick_force:float = 150
@export var max_normal_alignment:float = 180.0
@export var state_max_speed:float = 75.0
@export var fallingPitchSpeed:float = 0.8

# duration since the player left the ground
@export var ungrounded_grace:float = 2.0
var ungrounded_time:float = 0.0

# duration of a mid air leveling manuver, eased by a curve
@export var level_duration:float = 1.0
@export var easeInOut:Curve
var elapsed_time:float = 0.0
var duration:float = 1.0
var eased_t:float = 0.0

# Current speed
var forward_speed:float = 0.0

# Throttle input speed
var accel_input:float = 0.0

# deprecated
var target_speed:float = 0.0

# turn strength in radians
var turn_input:float = 0.0


var ship_statemachine:StateMachine
var is_grounded:bool = false
var average_terrain_normal:Vector3

signal camera_Y_offset

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	ship_statemachine = get_parent()

func enter(oldState:String, flags:Dictionary):
	if oldState == "Hovering":
		ShipContainer.transform = Transform3D()
		proxy_orb.transform = player.transform
		toggle_collision_shapes()
		target_speed = flags.get("target_speed")
		forward_speed = flags.get("forward_speed")
		proxy_orb.set_axis_velocity(flags.get("Player.velocity"))
	elif oldState == "Flying":
		pass
	else:
		proxy_orb.transform = player.transform

func update(delta:float):
	if ungrounded_time > 0.0:
		return

	if elapsed_time < level_duration:
		elapsed_time += delta
		var t = elapsed_time / level_duration
		eased_t = easeInOut.sample(t)		

func physicsUpdate(delta:float):
	get_input(delta)

	# turn ship
	if proxy_orb.linear_velocity.length() > turn_stop_limit:		
		var new_basis = proxy_xform.global_transform.basis.rotated(proxy_xform.global_basis.y, turn_input)
		proxy_xform.global_basis = proxy_xform.global_basis.slerp(new_basis, turn_force * delta)
		proxy_xform.global_transform = proxy_xform.global_transform.orthonormalized()

	# access the physics server directly for detailed contact information
	var physics_state = PhysicsServer3D.body_get_direct_state(proxy_orb.get_rid())
	var contact_count = physics_state.get_contact_count()
	forward_speed = physics_state.linear_velocity.length()
	var _normalized_forward_speed := forward_speed / state_max_speed
	var _stick_force = _normalized_forward_speed * ground_stick_force
	var _stick_curve_sample = StickCurve.sample(_normalized_forward_speed)
	if physics_state.linear_velocity.length() > state_max_speed:
		physics_state.linear_velocity = physics_state.linear_velocity.normalized() * state_max_speed

	proxy_xform.transform.origin = proxy_orb.transform.origin
	
	# check contact count to determine if grounded
	if contact_count > 0: # grounded
		if contact_count > 1: # get average normals, in case of multiple collisions
			var terrain_normals = Array()
			var sum_terrain_normals := Vector3.ZERO

			for i in range(physics_state.get_contact_count()):
				var normal = physics_state.get_contact_local_normal(i)
				terrain_normals.append(normal)

			for normal in terrain_normals:
				sum_terrain_normals += normal
			
			average_terrain_normal = sum_terrain_normals / float(terrain_normals.size())
		else:
			average_terrain_normal = physics_state.get_contact_local_normal(0)

		# Check the angle to the target rotation, if its too great, don't rotate!
		# var _player_quat:Quaternion = Quaternion(player.basis.orthonormalized())
		# var _target_quat:Quaternion = Quaternion(_xform.basis.orthonormalized())
		# var angle_to_target:float = rad_to_deg(_player_quat.angle_to(_target_quat))

		# if angle_to_target < max_normal_alignment:
		# 	player.global_transform = player.global_transform.interpolate_with(_xform, rolling_level_speed * delta).orthonormalized()

		var _xform = align_with_y(proxy_xform.global_transform, average_terrain_normal.normalized())
		proxy_xform.global_transform = proxy_xform.global_transform.interpolate_with(_xform, rolling_level_speed * delta)
		proxy_xform.global_transform = proxy_xform.global_transform.orthonormalized()
		
		# apply gravity and force
		proxy_orb.gravity_scale = gravity_grounded
		proxy_orb.apply_central_force(-average_terrain_normal * ground_stick_force * _stick_curve_sample)
		proxy_orb.apply_central_force(-player.basis.z * accel_force * accel_input)
		ungrounded_time = ungrounded_grace
		is_grounded = true
		SignalHub.tune_engine_effects.emit(_normalized_forward_speed, accel_input)

	else: # airborne
		if ungrounded_time > 0.0:
			ungrounded_time -= delta	
			var _xform = align_with_y(proxy_xform.global_transform, average_terrain_normal.normalized())
			proxy_xform.global_transform = proxy_xform.global_transform.interpolate_with(_xform, rolling_level_speed * delta)
			proxy_xform.global_transform = proxy_xform.global_transform.orthonormalized()
			proxy_orb.apply_central_force(-average_terrain_normal * ground_stick_force * _stick_curve_sample)
		else:
			# if elapsed_time < level_duration:
			# 	elapsed_time += delta
			# 	var t = elapsed_time / level_duration
			# 	eased_t = easeInOut.sample(t)	
			if is_grounded:
				elapsed_time = 0
			is_grounded = false

			# rotate towards the orbs forward direction, without turning
			var proxy_linear_velocity = physics_state.linear_velocity.normalized()
			var _right = Vector3.UP.cross(proxy_linear_velocity)
			var proxy_direction_up = proxy_linear_velocity.cross(_right)
			var _orb_local_up  = align_with_y(proxy_xform.global_transform, proxy_direction_up)
			proxy_xform.global_transform = proxy_xform.global_transform.interpolate_with(_orb_local_up, rolling_level_speed * delta * eased_t)
			proxy_xform.global_transform = proxy_xform.global_transform.orthonormalized()

			# rotate towards a neutral position, without changing the players forward direction
			# var proxy_linear_velocity = physics_state.linear_velocity.normalized()
			# if proxy_linear_velocity.length_squared() > 0.01:
			# 	var _target_basis = Basis.looking_at(proxy_linear_velocity, Vector3.UP)
			# 	var _final_basis = Basis(-player.global_basis.z.cross(_target_basis.y), _target_basis.y, player.global_basis.z) 
			# 	player.global_basis = player.basis.slerp(_final_basis, delta * rolling_level_speed).orthonormalized()
		# apply airborne gravity and input forces

		proxy_orb.gravity_scale = gravity_airborne
		proxy_orb.apply_central_force(-player.basis.z * accel_force * accel_input * 0.25)		
		SignalHub.tune_engine_effects.emit(_normalized_forward_speed, accel_input * 0.25, 2)

	
	# update player to orb position
	player.transform.origin = proxy_xform.transform.origin.slerp(proxy_orb.transform.origin, 0.5)
	player.transform = player.global_transform.interpolate_with(proxy_xform.transform, ship_statemachine.ship_stats.rolling_alignment_speed * delta)
	player.global_transform = player.global_transform.orthonormalized()

	
	# Roll the body based on the turn input
	ShipContainer.rotation.z = lerp(ShipContainer.rotation.z, turn_input*ship_statemachine.ship_stats.hovering_rollMultiplier, ship_statemachine.ship_stats.hovering_level_speed * delta)
	offset_camera_Y(delta)



func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform


func get_input(delta):
	# turning input
	turn_input = 0.0
	turn_input -= Input.get_action_strength("roll_right")
	turn_input += Input.get_action_strength("roll_left")
	turn_input *= deg_to_rad(turn_force)

	# Brake/Accelerate input
	accel_input = 0.0
	accel_input += Input.get_action_strength("pitch_down")
	accel_input -= Input.get_action_strength("pitch_up") * 0.4
	
	if Input.is_action_just_pressed("drift"):
		pass

	# if not Input.is_action_pressed("drift"):
	# 	var flags:Dictionary = {
	# 	"target_speed":target_speed,
	# 	"player.velocity":proxy_orb.velocity,
	# 	"forward_speed":forward_speed
	# 	}
	# 	toggle_collision_shapes()
	# 	finished.emit("Rolling", flags)


func toggle_collision_shapes():
	var player_collision_shapes:Array = Array()
	player_collision_shapes.append(%Player/ShipCollider)
	player_collision_shapes.append(%Player/GroundedRayCollider)
	var proxy_collision_shapes:Array = Array()
	proxy_collision_shapes.append(%RollingProxy/Orb)
	proxy_collision_shapes.append(%RollingProxy/Orb/WeBallNow)

	for shapes in player_collision_shapes:
		shapes.disabled = not shapes.disabled
	for shapes in proxy_collision_shapes:
		shapes.disabled = not shapes.disabled
	

func offset_camera_Y(delta:float):
	var _normalized_forward_speed = forward_speed / state_max_speed
	var targetY = _normalized_forward_speed * ship_statemachine.ship_stats.camera_Y_offset
	camera_Y_offset.emit(_normalized_forward_speed, targetY, delta)
