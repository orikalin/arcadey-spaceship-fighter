extends PlayerMovementState

@export var slide_boost_charge_speed: float = 4.0
@export var slide_boost_power_max: float = 4.0
@export var level_duration: float = 1.0
@export_range(0.0, 1.0, 0.01) var minimum_required_charge: float = 0.62
var elapsed_time: float = 0.0
var duration: float = 1.0
var eased_t: float = 0.0
var forward_speed: float = 0.0
var ungrounded_time: float = 0.0
var ship_mesh_tween: Tween
var state_max_speed_tween: Tween
var end_drift: bool = false
var slide_boost_power: float = 0.0
var slide_boost_charge_particle: GPUParticles3D
var slide_boost_star_particle: CPUParticles3D

@onready var ShipContainer: MeshInstance3D = %ShipContainer

signal camera_Y_offset


# Tumble state:
#   The idea is to make a state in which the player briefly loses control of their ship
#   due to being hit by some explosive or strong attacks, or by landing sideways or upsidedown
#   --checks for this will need to be implemeneted in other states
#   
#   recovery from this state will involve charging up a charged boost and relasing it.
#   --improve the visual effect of the charged state, and readability of perfect charge timing
#   --also implement perfect charge timing
#
#   during the tumble, the #ShipContainer will go into a free-spin-rotate tumble
#   and retarget the camera to chase the ShipOrb position, while giving the player the ability to
#   fight the tumble fight spin with stick inputs and influence the direction they are facing
#   --this can be implemented by controlling an existing quaternion or a new one made for the tumble state
#   --which will initially be aimed towards the ShipOrbs new forward, and lerp towards that with quickly diminishing speed
#   --the players inputs will have light influence over the lerp target
#   
#   also have the camera be swivelled around the Y-axis with the right stick inputs? this is something that might need to be tuned


func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	slide_boost_charge_particle = ShipContainer.get_charge_particles()
	slide_boost_star_particle = ShipContainer.get_charge_star()


func enter(oldState: String, flags: Dictionary):
	if proxy_orb.continuous_cd:
			proxy_orb.continuous_cd = false
	accel_input = abs(flags.get("accel_input"))
	physics_material.friction = 0.0
	end_drift = false
	print(accel_input)
	proxy_orb.physics_material_override = physics_material
	proxy_orb.linear_damp = ship_stats.drift_linear_damp
	SignalHub.set_starting_z.emit()
	SignalHub.tune_engine_cone_minmax.emit(0.1, 0.2)
	SignalHub.reset_Z_offset.emit(true)
	if ship_mesh_tween:
		ship_mesh_tween.kill()
	ship_mesh_tween = create_tween()
	ship_mesh_tween.set_trans(Tween.TRANS_QUAD)
	ship_mesh_tween.set_ease(Tween.EASE_OUT)
	ship_mesh_tween.tween_property(ShipContainer, "position", Vector3(0, -1.4, 0), 3.0)

	if oldState == "boost":
		SignalHub.camera_FOV_control.emit(75.0, 2.5)
		do_max_speed_tween()


func exit(newState: String):
	if ship_mesh_tween:
		ship_mesh_tween.kill()
	if state_max_speed_tween:
		state_max_speed_tween.kill()
	SignalHub.reset_Z_offset.emit()
	proxy_xform.global_transform = player.global_transform
	proxy_xform.global_transform = proxy_xform.global_transform.orthonormalized()
	slide_boost_power = 0.0
	slide_boost_star_particle.emitting = false

func update(delta: float):
	super(delta)
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
		var new_basis = player.global_transform.basis.rotated(player.global_basis.y, turn_input)
		player.global_basis = player.global_basis.slerp(new_basis, ship_stats.drift_turn_force * delta)
		player.global_transform = player.global_transform.orthonormalized()

	# access the physics server directly for detailed rigidbody information, and prepare some variables
	var physics_state = PhysicsServer3D.body_get_direct_state(proxy_orb.get_rid())
	# var contact_count = physics_state.get_contact_count()
	forward_speed = physics_state.linear_velocity.length()
	var _normalized_forward_speed: float = forward_speed / ship_stats.state_max_speed

	# This defines _stick_force based on forward speed. Higher speed = higher downward force applied, to helps cling to surfaces against gravity
	var _stick_force = _normalized_forward_speed * ship_stats.drift_ground_stick_force
	var _stick_curve_sample = ship_stats.stick_curve.sample(_normalized_forward_speed)

	proxy_xform.transform.origin = proxy_orb.transform.origin

	is_grounded = check_ground_normals()

	# while on the ground, align the ship to the averaged ground normals		
	if is_grounded:
		proxy_orb.gravity_scale = ship_stats.drift_gravity
		# align with the ground
		var _xform = align_with_y(proxy_xform.global_transform, average_terrain_normal.normalized())
		proxy_xform.global_transform = proxy_xform.global_transform.interpolate_with(_xform, ship_stats.ground_alignment_speed * delta)
		proxy_xform.global_transform = proxy_xform.global_transform.orthonormalized()

		_xform = align_with_y(player.global_transform, average_terrain_normal.normalized())
		player.global_transform = player.global_transform.interpolate_with(_xform, ship_stats.ground_alignment_speed * delta)
		player.global_transform = player.global_transform.orthonormalized()

		
		# apply gravity and force
		proxy_orb.gravity_scale = ship_stats.drift_gravity
		proxy_orb.apply_central_force(-average_terrain_normal * ship_stats.ground_stick_force * _stick_curve_sample)
		proxy_orb.apply_central_force(-proxy_xform.basis.z * ship_stats.accel_force * accel_input)
		ungrounded_time = ship_stats.drift_ungrounded_grace

		SignalHub.tune_engine_effects.emit(_normalized_forward_speed, accel_input)

	# while airborne, align to the direction of the orbs forward direction, without turning the player
	else:
		if ungrounded_time > 0.0:
			ungrounded_time -= delta
			proxy_orb.apply_central_force(-proxy_xform.basis.z * ship_stats.accel_force * accel_input * 0.5)
		# else: # end drift if ungrounded too long
		# 	end_drift = true
		# 	end_drift_state()
		else:
			# apply airborne gravity and input forces
			proxy_orb.gravity_scale = ship_stats.gravity_airborne
			proxy_orb.apply_central_force(-proxy_xform.basis.z * ship_stats.accel_force * accel_input * 0.15)
			proxy_orb.linear_damp = 0.04
			

	# clamps max speed
	_integrate_forces(physics_state)

	# update player to orb position
	player.transform.origin = proxy_xform.transform.origin.slerp(proxy_orb.transform.origin, 0.5)

	# this should rotate the xform towards the players rotation
	proxy_xform.transform = proxy_xform.global_transform.interpolate_with(player.transform, ship_stats.drift_player_alignment_speed * delta)
	proxy_xform.global_transform = proxy_xform.global_transform.orthonormalized()
	
	# Roll the body based on the turn input
	var _current_rotation = ShipContainer.rotation.z
	var _target_rotation = turn_input * ship_stats.drift_mesh_roll_multiplier
	var _weight = ship_stats.mesh_level_speed * delta
	ShipContainer.rotation.z = lerp(_current_rotation, _target_rotation, _weight)

	# offsets the phantom camera Y based on speed - experimenting with not adjusting during drift
	# offset_camera_Y(delta)
	SignalHub.camera_Z_offset.emit(player.global_basis, physics_state.linear_velocity.normalized())


func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = - xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform


func get_input(delta: float) -> void:
	(super.get_input(delta))
	turn_input *= deg_to_rad(ship_stats.drift_turn_force)

	# slide boost charge
	if Input.is_action_pressed("boost"):
		if slide_boost_power < slide_boost_power_max:
			slide_boost_power += delta * slide_boost_charge_speed
			slide_boost_charge_particle.emitting = true
		else:
			slide_boost_power = slide_boost_power_max
		
		if slide_boost_power > slide_boost_power_max * minimum_required_charge:
			slide_boost_star_particle.emitting = true
		else:
			slide_boost_star_particle.emitting = false

	elif slide_boost_power > 0:
		slide_boost_power -= delta
	elif slide_boost_power < 0:
		slide_boost_power = 0

	end_drift_state()
	
	
func end_drift_state():
	if not Input.is_action_pressed("drift") or end_drift:
		var flags: Dictionary = {
		"is_grounded": is_grounded,
		"slide_boost_power": slide_boost_power
		}
		if slide_boost_power > slide_boost_power_max * 0.75 and Input.is_action_pressed("boost"):
			finished.emit("charged_boost", flags)
		elif Input.is_action_pressed("boost") and ship_stats.boost_fuel_current > 0.001:
			finished.emit("boost", flags)
		else:
			finished.emit("hover", flags)


func offset_camera_Y(delta: float):
	var _normalized_forward_speed = forward_speed / ship_stats.state_max_speed
	var targetY = _normalized_forward_speed * ship_stats.camera_Y_offset
	camera_Y_offset.emit(_normalized_forward_speed, targetY, delta)


func do_max_speed_tween():
	if state_max_speed_tween:
		state_max_speed_tween.kill()
	state_max_speed_tween = create_tween()
	state_max_speed_tween.set_trans(Tween.TRANS_QUAD)
	state_max_speed_tween.set_ease(Tween.EASE_IN)
	state_max_speed_tween.tween_property(ship_stats, "state_max_speed", ship_stats.rolling_max_speed, ship_stats.drift_speed_decay_duration)


# func _integrate_forces(state):
# 	var _current_velocity = state.linear_velocity
# 	var _speed = _current_velocity.length()

# 	if _speed > ship_stats.state_max_speed:
# 		state.linear_velocity = _current_velocity.normalized() * ship_stats.state_max_speed
