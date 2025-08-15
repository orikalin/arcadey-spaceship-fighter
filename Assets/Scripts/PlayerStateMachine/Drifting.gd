extends State

@onready var ground_raycasts:Array = %ground_check_rays.get_children()

@export var player:CharacterBody3D
@export var proxy_xform:CharacterBody3D
@export var proxy_orb:RigidBody3D
@export var ShipContainer:MeshInstance3D
@export var physics_material:PhysicsMaterial

var ungrounded_time:float = 0.0

# duration of a mid air leveling manuver, eased by a curve
@export var level_duration:float = 1.0
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
var is_grounded:bool = false
var average_terrain_normal:Vector3
var gamepad:bool = false
var ship_mesh_tween:Tween
var state_max_speed_tween:Tween
var end_drift:bool = false

signal camera_Y_offset



## new drift state: while drifting, movement damping is reduced to (near) 0
## orb aligns to player much slower
## player turn speed increased, but coupled with the slower orb alignment, this should result in the player being able to rotate,
## while having minimal effect on their forward direction
## on releasing drift, exit to boost if boost is held, otherwise exit to hover

# currently: xform gets slerped to a target based on turn input, multiplied by turn_force
# xform is positioned to orb -> xform is aligned to ground -> proxy_orb gets force based on player -z 
# player slerped to xform position -> player interpolated with xform rotation
#
# for drift: player gets slerped to a target based on turn input, multiplied by turn_force #
# xform is positioned to orb #-> xform is aligned to ground #-> proxy_orb gets force based on xform -z #
# player slerped to xform position -> xform slerp towards player rotation


func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	ship_statemachine = get_parent()
	ship_stats = ship_statemachine.ship_stats

func enter(oldState:String, flags:Dictionary):
	end_drift = false
	accel_input = flags.get("accel_input")
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


func exit(newState:String):
	if ship_mesh_tween:
		ship_mesh_tween.kill()
	if state_max_speed_tween:
		state_max_speed_tween.kill()
	SignalHub.reset_Z_offset.emit()		
	proxy_xform.global_transform = player.global_transform
	proxy_xform.global_transform = proxy_xform.global_transform.orthonormalized()

func update(delta:float):
	if ungrounded_time > 0.0:
		return

	if elapsed_time < level_duration:
		elapsed_time += delta
		var t = elapsed_time / level_duration
		eased_t = ship_stats.easeInOut.sample(t)		

func physicsUpdate(delta:float):
	get_input()
	# turn ship
	if proxy_orb.linear_velocity.length() > ship_stats.turn_stop_limit:		
		var new_basis = player.global_transform.basis.rotated(player.global_basis.y, turn_input)
		player.global_basis = player.global_basis.slerp(new_basis, ship_stats.drift_turn_force * delta)
		player.global_transform = player.global_transform.orthonormalized()

	# access the physics server directly for detailed rigidbody information, and prepare some variables
	var physics_state = PhysicsServer3D.body_get_direct_state(proxy_orb.get_rid())
	var contact_count = physics_state.get_contact_count()
	forward_speed = physics_state.linear_velocity.length()
	var _normalized_forward_speed := forward_speed / ship_stats.state_max_speed

	# This defines _stick_force based on forward speed. Higher speed = higher downward force applied, to helps cling to surfaces against gravity
	var _stick_force = _normalized_forward_speed * ship_stats.drift_ground_stick_force
	var _stick_curve_sample = ship_stats.stick_curve.sample(_normalized_forward_speed)

	proxy_xform.transform.origin = proxy_orb.transform.origin

	## Use 5 downward raycasts on the proxy xform to get the average of the normals below the player
	## if anyone of the 5 are contacting terrain, the player is considered grounded
	var _terrain_normals:Array
	var _sum_terrain_normals := Vector3.ZERO

	# check the 5 raycasts, get the average normal of all terrain hit, mark as grounded if any hit terrain
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

		_xform = align_with_y(player.global_transform, average_terrain_normal.normalized())
		player.global_transform = player.global_transform.interpolate_with(_xform, ship_stats.ground_alignment_speed * delta)
		player.global_transform = player.global_transform.orthonormalized()

		
		# apply gravity and force
		proxy_orb.gravity_scale = ship_stats.drift_gravity
		proxy_orb.apply_central_force(-average_terrain_normal * ship_stats.ground_stick_force * _stick_curve_sample)
		proxy_orb.apply_central_force(-proxy_xform.basis.z * ship_stats.accel_force * accel_input)
		ungrounded_time = ship_stats.drift_ungrounded_grace

		SignalHub.tune_engine_effects.emit(_normalized_forward_speed, accel_input)
		SignalHub.camera_Z_offset.emit()

	## while airborne, align to the direction of the orbs forward direction, without turning the player
	else: 
		if ungrounded_time > 0.0:
			ungrounded_time -= delta
			proxy_orb.apply_central_force(-proxy_xform.basis.z * ship_stats.accel_force * accel_input * 0.5)
		else: # end drift if ungrounded too long
			end_drift = true
			end_drift_state()
		
		# apply airborne gravity and input forces
		proxy_orb.apply_central_force(-proxy_xform.basis.z * ship_stats.accel_force * accel_input)		

	# # clamps max speed
	# if physics_state.linear_velocity.length() > ship_stats.state_max_speed: 
	# 	physics_state.linear_velocity = physics_state.linear_velocity.normalized() * ship_stats.state_max_speed
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
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform


func get_input():
	# turning input
	turn_input = 0.0
	turn_input -= Input.get_action_strength("roll_right")
	turn_input += Input.get_action_strength("roll_left")
	turn_input *= deg_to_rad(ship_stats.drift_turn_force)

	# Brake/Accelerate input
	# accel_input = 1.0
	# if  gamepad:
	# 	if Input.is_action_pressed("throttle_up"):
	# 		accel_input += 1
	# 	elif gamepad and Input.is_action_pressed("throttle_down"):
	# 		accel_input -= 0.4
	# else:
	# 	accel_input += Input.get_action_strength("pitch_down")
	# 	accel_input -= Input.get_action_strength("pitch_up") * 0.4


	end_drift_state()
	
func end_drift_state():
	if not Input.is_action_pressed("drift") or end_drift:
		var flags:Dictionary = {
		"is_grounded":is_grounded
		}
		
		if Input.is_action_pressed("boost"):
			finished.emit("boost", flags)
		else:	
			finished.emit("hover", flags)

func offset_camera_Y(delta:float):
	var _normalized_forward_speed = forward_speed / ship_stats.state_max_speed
	var targetY = _normalized_forward_speed * ship_stats.camera_Y_offset
	camera_Y_offset.emit(_normalized_forward_speed, targetY, delta)

func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouse:
		gamepad = false
	elif event is InputEventJoypadMotion or event is InputEventJoypadButton:
		gamepad = true

func _integrate_forces(state):
	var _current_velocity = state.linear_velocity
	var _speed = _current_velocity.length()

	if _speed > ship_stats.state_max_speed:
		state.linear_velocity = _current_velocity.normalized() * ship_stats.state_max_speed


func do_max_speed_tween():
	if state_max_speed_tween:
		state_max_speed_tween.kill()
	state_max_speed_tween = create_tween()
	state_max_speed_tween.set_trans(Tween.TRANS_QUAD)
	state_max_speed_tween.set_ease(Tween.EASE_IN)
	state_max_speed_tween.tween_property(ship_stats, "state_max_speed", ship_stats.rolling_max_speed, ship_stats.drift_speed_decay_duration)
