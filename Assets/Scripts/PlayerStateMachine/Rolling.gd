extends PlayerMovementState

@export var accel_multiplier: float = 1.0
var ungrounded_time: float = 0.0

# duration of a mid air leveling manuver, eased by a curve
@export var level_duration: float = 1.0
var elapsed_time: float = 0.0
var duration: float = 1.0
var eased_t: float = 0.0

# Current speed
var forward_speed: float = 0.0

# Throttle input speed
var accel_input: float = 0.0

# deprecated
var target_speed: float = 0.0

# turn strength in radians
var turn_input: float = 0.0


var ship_statemachine: StateMachine
var is_grounded: bool = false
var state_max_speed_tween: Tween
var ship_mesh_tween: Tween
var accel_held: bool = false
var pitch_input: float = 0.0

@onready var ShipContainer: MeshInstance3D = %ShipContainer

signal camera_Y_offset

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))

func enter(oldState: String, flags: Dictionary):
	physics_material.friction = 0.1
	physics_material.bounce = 0.0
	proxy_orb.physics_material_override = physics_material
	proxy_orb.linear_damp = ship_stats.linear_damp
	accel_input = abs(accel_input)
	SignalHub.tune_engine_cone_minmax.emit(0.1, 0.9)

	if oldState == "boost" or oldState == "charged_boost":
		do_max_speed_tween()
		SignalHub.camera_FOV_control.emit(75.0, 1.5)
	elif oldState == "drift":
		do_max_speed_tween()
		is_grounded = flags.get("is_grounded")
		SignalHub.camera_FOV_control.emit(75.0, 1.5)
		if ship_mesh_tween:
			ship_mesh_tween.kill()
		ship_mesh_tween = create_tween()
		ship_mesh_tween.set_trans(Tween.TRANS_QUAD)
		ship_mesh_tween.set_ease(Tween.EASE_OUT)
		ship_mesh_tween.tween_property(ShipContainer, "position", Vector3.ZERO, 2.0)
	else:
		ship_stats.state_max_speed = ship_stats.rolling_max_speed
		proxy_xform.transform = player.transform
		proxy_orb.transform = player.transform

func exit(newState: String):
	if newState == "boost":
		if state_max_speed_tween:
			state_max_speed_tween.kill()
	elif newState == "drift":
		if ship_mesh_tween:
			ship_mesh_tween.kill()

func update(delta: float):
	if ungrounded_time > 0.0:
		return

	if elapsed_time < level_duration:
		elapsed_time += delta
		var t = elapsed_time / level_duration
		eased_t = ship_stats.easeInOut.sample(t)

func physicsUpdate(delta: float):
	get_input(delta)

	# turn ship
	if proxy_orb.linear_velocity.length() > ship_stats.turn_stop_limit:
		var new_basis = proxy_xform.global_transform.basis.rotated(proxy_xform.global_basis.y, turn_input)
		proxy_xform.global_basis = proxy_xform.global_basis.slerp(new_basis, ship_stats.rolling_turn_force * delta)
		proxy_xform.global_transform = proxy_xform.global_transform.orthonormalized()

	# access the physics server directly for detailed rigidbody information, and prepare some variables
	var physics_state = PhysicsServer3D.body_get_direct_state(proxy_orb.get_rid())
	forward_speed = physics_state.linear_velocity.length()
	var _normalized_forward_speed: float = forward_speed / ship_stats.state_max_speed

	# This defines _stick_force based on forward speed. Higher speed = higher downward force applied, to helps cling to surfaces against gravity
	var _stick_force = _normalized_forward_speed * ship_stats.ground_stick_force
	var _stick_curve_sample = ship_stats.stick_curve.sample(_normalized_forward_speed)

	proxy_xform.transform.origin = proxy_orb.transform.origin

	is_grounded = check_ground_normals() 

	## while on the ground, align the ship to the averaged ground normals		
	if is_grounded:
		## align with the ground
		var _xform = align_with_y(proxy_xform.global_transform, average_terrain_normal.normalized())
		proxy_xform.global_transform = proxy_xform.global_transform.interpolate_with(_xform, ship_stats.ground_alignment_speed * delta)
		proxy_xform.global_transform = proxy_xform.global_transform.orthonormalized()
		
		## apply gravity and force
		proxy_orb.gravity_scale = ship_stats.gravity_grounded
		proxy_orb.apply_central_force(-average_terrain_normal * ship_stats.ground_stick_force * _stick_curve_sample)
		proxy_orb.apply_central_force(-player.basis.z * ship_stats.accel_force * accel_input)
		ungrounded_time = ship_stats.ungrounded_grace

		SignalHub.tune_engine_effects.emit(_normalized_forward_speed, accel_input)

	## while airborne, align to the direction of the orbs forward direction, without turning the player
	else:
		if ungrounded_time > 0.0:
			ungrounded_time -= delta
			proxy_orb.apply_central_force(-average_terrain_normal * ship_stats.ground_stick_force * _stick_curve_sample)
		else:
			if is_grounded:
				elapsed_time = 0
			is_grounded = false

			## rotate towards the orbs forward direction, without turning, within limits
			var _orb_linear_velocity = physics_state.linear_velocity.normalized()
			var _right = Vector3.UP.cross(_orb_linear_velocity)
			var _proxy_direction_up = _orb_linear_velocity.cross(_right)
			var _orb_local_up = align_with_y(proxy_xform.global_transform, _proxy_direction_up)

			if abs(pitch_input) < 0.001:
				proxy_xform.global_transform = proxy_xform.global_transform.interpolate_with(_orb_local_up, ship_stats.falling_level_speed * delta)
				proxy_xform.global_transform = proxy_xform.global_transform.orthonormalized()
			
			else: ## use input of right stick to control pitch
				proxy_xform.transform.basis = proxy_xform.transform.basis.rotated(proxy_xform.transform.basis.x, pitch_input * ship_stats.flying_pitch_speed * delta)

		
		# apply airborne gravity and input forces
		proxy_orb.gravity_scale = ship_stats.gravity_airborne
		proxy_orb.apply_central_force(-player.basis.z * ship_stats.accel_force * accel_input * 0.25)
		SignalHub.tune_engine_effects.emit(_normalized_forward_speed, accel_input * 0.25, 2)

	if accel_input > 0 and not accel_held:
		accel_input = lerp(accel_input, 0.0, delta * ship_stats.max_speed_decay_multiplier)
	elif not accel_held:
		accel_input = 0

	# clamps max speed
	_integrate_forces(physics_state)

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
	if physics_state.linear_velocity.length() > 2:
		SignalHub.camera_Z_offset.emit(player.global_basis, physics_state.linear_velocity.normalized())


func do_max_speed_tween():
	if state_max_speed_tween:
		state_max_speed_tween.kill()
	state_max_speed_tween = create_tween()
	state_max_speed_tween.set_trans(Tween.TRANS_QUART)
	state_max_speed_tween.set_ease(Tween.EASE_OUT)
	state_max_speed_tween.tween_property(ship_stats, "state_max_speed", ship_stats.rolling_max_speed, ship_stats.max_speed_decay_duration)


func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = - xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform


func get_input(delta: float):
	# turning input
	turn_input = 0.0
	turn_input -= Input.get_action_strength("roll_right")
	turn_input += Input.get_action_strength("roll_left")
	turn_input *= deg_to_rad(ship_stats.rolling_turn_force)

	if Input.is_action_pressed("throttle_up"):
		if accel_input < 1:
			accel_input += delta * accel_multiplier
		else:
			accel_input = 1
		accel_held = true

	elif Input.is_action_pressed("throttle_down"):
		accel_input = -0.4
		accel_held = true
	else:
		accel_held = false
	
	if Input.is_action_pressed("drift") and is_grounded:
		var flags: Dictionary = {
		"forward_speed": forward_speed,
		"accel_input": accel_input
		}
		finished.emit("drift", flags)

	elif Input.is_action_pressed("boost") and ship_stats.boost_fuel_current > 0.001:
		var flags: Dictionary = {
		"forward_speed": forward_speed
		}
		finished.emit("boost", flags)
	
	pitch_input = 0.0
	pitch_input += Input.get_action_strength("r_stick_up")
	pitch_input -= Input.get_action_strength("r_stick_down")
	

func offset_camera_Y(delta: float):
	var _normalized_forward_speed = forward_speed / ship_stats.state_max_speed
	var targetY = _normalized_forward_speed * ship_stats.camera_Y_offset
	camera_Y_offset.emit(_normalized_forward_speed, targetY, delta)

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouse:
		gamepad = false
	elif event is InputEventJoypadMotion or event is InputEventJoypadButton:
		gamepad = true
