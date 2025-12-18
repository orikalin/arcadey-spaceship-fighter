extends PlayerMovementState

@export var level_duration: float = 3.0
@export var charge_boost_decay: Curve

var elapsed_time: float = 0.0
var duration: float = 1.0
var eased_t: float = 0.0
var ungrounded_time: float = 0.0
var forward_speed: float = 0.0
var ship_statemachine: StateMachine
var boost_duration: float = 0.0
var ship_mesh_tween: Tween
var boosted_max_speed: float

signal camera_Y_offset

@onready var ShipContainer: MeshInstance3D = %ShipContainer


func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))


func enter(oldState: String, flags: Dictionary = {}):
	accel_input = 1.0
	physics_material.friction = 0.7
	proxy_orb.physics_material_override = physics_material
	proxy_orb.linear_damp = ship_stats.linear_damp
	boost_duration = 0.0
	SignalHub.tune_engine_cone_minmax.emit(1.0, 1.5)
	SignalHub.camera_FOV_control.emit(105.0, 5.0)
	if %hover.state_max_speed_tween:
		%hover.state_max_speed_tween.kill()
	if oldState == "drift":
		ship_stats.state_max_speed = ship_stats.boost_max_speed
		is_grounded = flags.get("is_grounded")
		if ship_mesh_tween:
			ship_mesh_tween.kill()
		ship_mesh_tween = create_tween()
		ship_mesh_tween.set_trans(Tween.TRANS_QUAD)
		ship_mesh_tween.set_ease(Tween.EASE_OUT)
		ship_mesh_tween.tween_property(ShipContainer, "position", Vector3.ZERO, 1.0)
	elif oldState == "charged_boost":
		if flags.has("state_boosted_speed"):
			ship_stats.state_max_speed = flags.get("state_boosted_speed")
		boosted_max_speed = ship_stats.state_max_speed
		print_debug(ship_stats.state_max_speed)
	else:
		ship_stats.state_max_speed = ship_stats.boost_max_speed
	# if oldState == "hover":
	# 	forward_speed = flags.get("forward_speed")
	# elif oldState == "Flying":
	# 	pass
	# else:
	# 	proxy_xform.transform = player.transform
	# 	proxy_orb.transform = player.transform

func update(delta: float):
	ship_stats.boost_fuel_current -= delta * ship_stats.fuel_drain_rate
	if ship_stats.state_max_speed > ship_stats.boost_max_speed:
		var _sample = charge_boost_decay.sample(boost_duration * 0.5)
		ship_stats.state_max_speed = lerp(boosted_max_speed, ship_stats.boost_max_speed, _sample)
	boost_duration += delta
	if ungrounded_time > 0.0:
		return

	if elapsed_time < level_duration:
		elapsed_time += delta
		var t = elapsed_time / level_duration
		eased_t = ship_stats.easeInOut.sample(t)

func physicsUpdate(delta: float):
	# Boost: instantly increase max speed, higher values for accel force and stick force #
	# by picking up fuel dropped by enemies and breakable objects
	# boost has a minimum duration #
	# when returning to rolling state, max speed will be reduced sharply at first, then ease out from boost_max to rolling_max
	get_input(delta)

	# turn ship
	if proxy_orb.linear_velocity.length() > ship_stats.turn_stop_limit:
		var new_basis = proxy_xform.global_transform.basis.rotated(proxy_xform.global_basis.y, turn_input)
		proxy_xform.global_basis = proxy_xform.global_basis.slerp(new_basis, ship_stats.rolling_turn_force * delta)
		proxy_xform.global_transform = proxy_xform.global_transform.orthonormalized()

	# access the physics server directly for detailed rigidbody information, and prepare some variables
	# var contact_count = physics_state.get_contact_count()
	var physics_state = PhysicsServer3D.body_get_direct_state(proxy_orb.get_rid())
	forward_speed = physics_state.linear_velocity.length()
	var _normalized_forward_speed: float = forward_speed / ship_stats.rolling_max_speed

	# This defines _stick_force based on forward speed. Higher speed = higher downward force applied, to helps cling to surfaces against gravity
	var _stick_force = _normalized_forward_speed * ship_stats.ground_stick_force
	var _stick_curve_sample = ship_stats.stick_curve.sample(_normalized_forward_speed)

	proxy_xform.transform.origin = proxy_orb.transform.origin

	is_grounded = check_ground_normals()

	# while on the ground, align the ship to the averaged ground normals		
	if is_grounded:
		proxy_orb.linear_damp = ship_stats.linear_damp
		# align with the ground
		var _xform = align_with_y(proxy_xform.global_transform, average_terrain_normal.normalized())
		proxy_xform.global_transform = proxy_xform.global_transform.interpolate_with(_xform, ship_stats.boost_ground_alignment_speed * delta)
		proxy_xform.global_transform = proxy_xform.global_transform.orthonormalized()
		
		# apply gravity and force
		proxy_orb.gravity_scale = 0.2
		var _forward_vector = -player.basis.z * ship_stats.boost_accel_force * accel_input
		var _downward_vector = -average_terrain_normal * ship_stats.boost_ground_stick_force * _stick_curve_sample
		var _average_vector = (_forward_vector + _downward_vector)

		proxy_orb.apply_central_force(_average_vector)
		# proxy_orb.apply_central_force(-average_terrain_normal * ship_stats.boost_ground_stick_force * _stick_curve_sample)
		# proxy_orb.apply_central_force(-player.basis.z * ship_stats.boost_accel_force * accel_input)
		ungrounded_time = ship_stats.ungrounded_grace

		SignalHub.tune_engine_effects.emit(_normalized_forward_speed, accel_input, ship_stats.cone_flare_mult)


	# while airborne, align to the direction of the orbs forward direction, without turning the player
	else:
		if ungrounded_time > 0.0:
			proxy_orb.linear_damp = ship_stats.linear_damp
			ungrounded_time -= delta
			proxy_orb.apply_central_force(-average_terrain_normal * ship_stats.boost_ground_stick_force * _stick_curve_sample)
			proxy_orb.apply_central_force(-player.basis.z * ship_stats.boost_accel_force * accel_input)
		else:
			if is_grounded:
				elapsed_time = 0
			is_grounded = false
			# rotate towards the orbs forward direction, without turning, within limits
			var _orb_linear_velocity = physics_state.linear_velocity.normalized()
			var _right = Vector3.UP.cross(_orb_linear_velocity)
			var _proxy_direction_up = _orb_linear_velocity.cross(_right)
			var _orb_local_up = align_with_y(proxy_xform.global_transform, _proxy_direction_up)

			proxy_orb.linear_damp = 0.04

			if abs(pitch_input) < 0.001:
				proxy_xform.global_transform = proxy_xform.global_transform.interpolate_with(_orb_local_up, ship_stats.falling_level_speed * delta)
				proxy_xform.global_transform = proxy_xform.global_transform.orthonormalized()

			else: # use input of right stick to control pitch
				proxy_xform.transform.basis = proxy_xform.transform.basis.rotated(proxy_xform.transform.basis.x, pitch_input * ship_stats.flying_pitch_speed * delta)
		
			# apply airborne gravity and input forces
			proxy_orb.gravity_scale = ship_stats.gravity_airborne
			proxy_orb.apply_central_force(-player.basis.z * ship_stats.accel_force * accel_input * 0.15)
			SignalHub.tune_engine_effects.emit(_normalized_forward_speed, accel_input * 0.25, 2)

	# clamps max speed
	_integrate_forces(physics_state)

	# update player to orb position
	player.transform.origin = proxy_xform.transform.origin.slerp(proxy_orb.transform.origin, 0.5)
	player.transform = player.global_transform.interpolate_with(proxy_xform.transform, ship_stats.boost_player_alignment_speed * delta)
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
	xform.basis.x = - xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform


	# Boosting inputs
	# Add inputs for handling a hover slide boost: this occurs when you start drifting. I'm not sure how I want this to work yet, here are the two ideas:
	# 1. Entering a drift starts charging up the slide boost, upon releasing the drift, IF the player is holding boost, switch to the boost state and do a boost with very high acceleration
	# 2. Entering a drift starts charging up the slide boost. Upon pressing the boost button, drift state will be exited, and a high accel boost will be performed.
	# 3. The guage will only charge up if the player is holding boost while drifting. If drift is released, the boost gauge will diminish over time. The high accel boost will only happen if the player is holding boost upon drift release.
	# in all of these cases, the acceleration increase will be a multiplier based on the boost gauge, starting at 1.0 and going up to 4.0? at max
	# this the additional resulting acceleration will temporarily raise the max speed of the boost state, which will return to its base max over a short time.
	# consider applying the high acceleration bonus to hover mode in matching situations, whatever version is chosen.
func get_input(delta):
	(super.get_input(delta))
	
	# State specific input logic
	turn_input *= deg_to_rad(ship_stats.boost_turn_force)
	if not Input.is_action_pressed("boost") and boost_duration > ship_stats.boost_min_duration:
		var flags: Dictionary = {
		"forward_speed": forward_speed,
		"old_max_speed": ship_stats.state_max_speed
		}
		finished.emit("hover", flags)

	elif ship_stats.boost_fuel_current < 0.001:
		var flags: Dictionary = {
		"forward_speed": forward_speed,
		"old_max_speed": ship_stats.state_max_speed
		}
		finished.emit("hover", flags)

	elif Input.is_action_pressed("drift") and is_grounded:
		var flags: Dictionary = {
		"forward_speed": forward_speed,
		"accel_input": accel_input
		}
		finished.emit("drift", flags)


func toggle_collision_shapes():
	var player_collision_shapes: Array = Array()
	player_collision_shapes.append(%Player/ShipCollider)
	player_collision_shapes.append(%Player/GroundedRayCollider)
	var proxy_collision_shapes: Array = Array()
	proxy_collision_shapes.append(%RollingProxy/Orb)
	proxy_collision_shapes.append(%RollingProxy/Orb/WeBallNow)

	for shapes in player_collision_shapes:
		shapes.disabled = not shapes.disabled
	for shapes in proxy_collision_shapes:
		shapes.disabled = not shapes.disabled
	

func offset_camera_Y(delta: float):
	var _normalized_forward_speed = forward_speed / ship_stats.state_max_speed
	var targetY = _normalized_forward_speed * ship_stats.boost_cam_Y_offset
	camera_Y_offset.emit(_normalized_forward_speed, targetY, delta)

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouse:
		gamepad = false
	elif event is InputEventJoypadMotion or event is InputEventJoypadButton:
		gamepad = true

# func _integrate_forces(state):
# 	var _current_velocity = state.linear_velocity
# 	var _speed = _current_velocity.length()

# 	# if _speed > ship_stats.state_max_speed:
# 	# 	state.linear_velocity = _current_velocity.normalized() * ship_stats.state_max_speed
