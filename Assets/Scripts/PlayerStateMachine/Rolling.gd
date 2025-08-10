extends State

@onready var ground_raycasts:Array = %ground_check_rays.get_children()

@export var player:CharacterBody3D
@export var proxy_xform:CharacterBody3D
@export var proxy_orb:RigidBody3D
@export var ShipContainer:MeshInstance3D

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
var ship_stats:ShipResource
var state_max_speed:float
var is_grounded:bool = false
var average_terrain_normal:Vector3
var gamepad:bool = false

signal camera_Y_offset

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	ship_statemachine = get_parent()
	ship_stats = ship_statemachine.ship_stats
	state_max_speed = ship_stats.rolling_max_speed

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
		proxy_xform.transform = player.transform
		proxy_orb.transform = player.transform

func update(delta:float):
	if ungrounded_time > 0.0:
		return

	if elapsed_time < level_duration:
		elapsed_time += delta
		var t = elapsed_time / level_duration
		eased_t = easeInOut.sample(t)		

func physicsUpdate(delta:float):
	state_max_speed = ship_stats.rolling_max_speed
	get_input(delta)

	# turn ship
	if proxy_orb.linear_velocity.length() > ship_stats.turn_stop_limit:		
		var new_basis = proxy_xform.global_transform.basis.rotated(proxy_xform.global_basis.y, turn_input)
		proxy_xform.global_basis = proxy_xform.global_basis.slerp(new_basis, ship_stats.rolling_turn_force * delta)
		proxy_xform.global_transform = proxy_xform.global_transform.orthonormalized()

	# access the physics server directly for detailed contact information, and prepare some variables
	var physics_state = PhysicsServer3D.body_get_direct_state(proxy_orb.get_rid())
	var contact_count = physics_state.get_contact_count()
	forward_speed = physics_state.linear_velocity.length()
	var _normalized_forward_speed := forward_speed / state_max_speed

	# This defines _stick_force based on forward speed. Higher speed = higher downward force applied, to helps cling to surfaces against gravity
	var _stick_force = _normalized_forward_speed * ship_stats.ground_stick_force
	var _stick_curve_sample = ship_stats.stick_curve.sample(_normalized_forward_speed)
	if physics_state.linear_velocity.length() > state_max_speed:
		physics_state.linear_velocity = physics_state.linear_velocity.normalized() * state_max_speed

	proxy_xform.transform.origin = proxy_orb.transform.origin

	## Use 5 downward raycasts on the proxy xform to get the average of the normals below the player
	## if anyone of the 5 are contacting terrain, the player is considered grounded
	var _terrain_normals:Array
	var _sum_terrain_normals := Vector3.ZERO
	var _new_average_terrain_normal:Vector3
	for raycast:RayCast3D in ground_raycasts:
		var _raycast_hit := raycast.get_collider()
		if _raycast_hit != null:
			if _raycast_hit.get_collision_mask_value(1):
				_terrain_normals.append(raycast.get_collision_normal())
	if _terrain_normals.size() > 0:
		for _normal in _terrain_normals:
			_sum_terrain_normals += _normal
		average_terrain_normal = _sum_terrain_normals / _terrain_normals.size()
		is_grounded = true
	else:
		is_grounded = false

	## while on the ground, align the ship to the averaged ground normals		
	if is_grounded:
		# align with the ground
		var _xform = align_with_y(proxy_xform.global_transform, average_terrain_normal.normalized())
		proxy_xform.global_transform = proxy_xform.global_transform.interpolate_with(_xform, ship_stats.ground_alignment_speed * delta)
		proxy_xform.global_transform = proxy_xform.global_transform.orthonormalized()
		
		# apply gravity and force
		proxy_orb.gravity_scale = ship_stats.gravity_grounded
		proxy_orb.apply_central_force(-average_terrain_normal * ship_stats.ground_stick_force * _stick_curve_sample)
		proxy_orb.apply_central_force(-player.basis.z * ship_stats.accel_force * accel_input)
		ungrounded_time = ungrounded_grace

		SignalHub.tune_engine_effects.emit(_normalized_forward_speed, accel_input)

	else:
		if ungrounded_time > 0.0:
			ungrounded_time -= delta	
			proxy_orb.apply_central_force(-average_terrain_normal * ship_stats.ground_stick_force * _stick_curve_sample)
		else:	
			if is_grounded:
				elapsed_time = 0
			is_grounded = false
			# rotate towards the orbs forward direction, without turning
			var _proxy_linear_velocity = physics_state.linear_velocity.normalized()
			var _right = Vector3.UP.cross(_proxy_linear_velocity)
			var _proxy_direction_up = _proxy_linear_velocity.cross(_right)
			var _orb_local_up  = align_with_y(proxy_xform.global_transform, _proxy_direction_up)
			proxy_xform.global_transform = proxy_xform.global_transform.interpolate_with(_orb_local_up, ship_stats.falling_level_speed * delta * eased_t)
			proxy_xform.global_transform = proxy_xform.global_transform.orthonormalized()
		
		# apply airborne gravity and input forces
		proxy_orb.gravity_scale = ship_stats.gravity_airborne
		proxy_orb.apply_central_force(-player.basis.z * ship_stats.accel_force * accel_input * 0.25)		
		SignalHub.tune_engine_effects.emit(_normalized_forward_speed, accel_input * 0.25, 2)

	# update player to orb position
	player.transform.origin = proxy_xform.transform.origin.slerp(proxy_orb.transform.origin, 0.5)
	player.transform = player.global_transform.interpolate_with(proxy_xform.transform, ship_stats.player_alignment_speed * delta)
	player.global_transform = player.global_transform.orthonormalized()
	
	# Roll the body based on the turn input
	var _current_rotation = ShipContainer.rotation.z
	var _target_rotation = turn_input * ship_stats.mesh_roll_multiplier
	var _weight = ship_stats.mesh_level_speed * delta
	ShipContainer.rotation.z = lerp(_current_rotation, _target_rotation, _weight)

	# offsets the phantom camera Y based on speed
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
	turn_input *= deg_to_rad(ship_stats.rolling_turn_force)

	# Brake/Accelerate input
	accel_input = 0.0
	if  gamepad:
		if Input.is_action_pressed("throttle_up"):
			accel_input += 1
		elif gamepad and Input.is_action_pressed("throttle_down"):
			accel_input -= 0.4
	else:
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
	var targetY = _normalized_forward_speed * ship_stats.camera_Y_offset
	camera_Y_offset.emit(_normalized_forward_speed, targetY, delta)

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouse:
		gamepad = false
	elif event is InputEventJoypadMotion or event is InputEventJoypadButton:
		gamepad = true
