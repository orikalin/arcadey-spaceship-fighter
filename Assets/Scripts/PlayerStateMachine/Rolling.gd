extends State

@export var player:CharacterBody3D
@export var proxy:RigidBody3D
@export var ShipContainer:MeshInstance3D
@export var floor_raycast:RayCast3D
@export var falling_damping_curve:Curve

# Current speed
var forward_speed:float = 0.0
# Throttle input speed
var target_speed:float = 0.0
var turn_input:float = 0.0
var accel_input:float = 0.0
var ship_statemachine:StateMachine
var is_grounded:bool = false
var ungrounded_time:float = 0
@export var ungrounded_grace:float = 2.0

@export var accel_force:float
@export var turn_force:float 
@export var turn_stop_limit:float
@export var rolling_level_speed:float = 10.0
@export var gravity_airborne:float = 0.0
@export var gravity_grounded:float = 4.0
signal camera_Y_offset

func _ready():
	connect("body_entered", Callable(self, "_on_body_entered"))
	connect("body_exited", Callable(self, "_on_body_exited"))
	ship_statemachine = get_parent()

func enter(oldState:String, flags:Dictionary):
	if oldState == "Hovering":
		proxy.transform = player.transform
		toggle_collision_shapes()
		target_speed = flags.get("target_speed")
		forward_speed = flags.get("forward_speed")
		proxy.set_axis_velocity(flags.get("Player.velocity"))
		# example for how to change phantom camera priority on state change
		# ship_statemachine.phantom_camera_shift.emit(5)

# func exit(newState:String, flags:Dictionary):
# 	ship_statemachine.phantom_camera_shift.emit(0)
		

func physicsUpdate(delta:float):

	get_input(delta)
	if proxy.linear_velocity.length() > turn_stop_limit:
		var new_basis = player.global_transform.basis.rotated(player.global_basis.y, turn_input)
		player.global_basis = player.global_basis.slerp(new_basis, turn_force * delta)
		player.global_transform = player.global_transform.orthonormalized()

	# get ground normal to rotate ShipContainer NOT player
	if is_grounded or ungrounded_time > 0.0:
		var _state = PhysicsServer3D.body_get_direct_state(proxy.get_rid())
		var terrain_normal = _state.get_contact_local_normal(0)
		var xform = align_with_y(player.global_transform, terrain_normal.normalized())
		ShipContainer.global_transform = ShipContainer.global_transform.interpolate_with(xform, rolling_level_speed * delta)
		ShipContainer.global_transform = ShipContainer.global_transform.orthonormalized()
		proxy.gravity_scale = gravity_grounded
	else:
		ShipContainer.global_transform = ShipContainer.global_transform.interpolate_with(player.transform, rolling_level_speed * 0.5 * delta)
		if ungrounded_time <= 0.0:
			proxy.gravity_scale = gravity_airborne
		else:
			ungrounded_time -= delta



	proxy.apply_central_force(-player.basis.z * accel_force * accel_input)
	#proxy.apply_central_force()

	#if is_grounded:
		# adjust the proxy's forward based on player forward
		# var angle = player.basis.z.signed_angle_to(proxy.basis.z, -player.basis.y) # get the different in angle
		# proxy.transform.basis = proxy.transform.basis.rotated(Vector3.UP, angle * ship_statemachine.ship_stats.drift_proxy_turn_speed * delta) 	
		


	player.transform.origin = proxy.transform.origin
	player.transform = player.global_transform.interpolate_with(ShipContainer.global_transform, rolling_level_speed * delta)
	player.global_transform = player.global_transform.orthonormalized()
	# if grounded:
	# align_to_floor_normal(delta, false)


func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform

func align_to_floor_normal(delta, instant:bool):
	var floor_normal = floor_raycast.get_collision_normal()
	var target_normal_local = floor_normal * proxy.basis
	var target_pitch = atan2(target_normal_local.z, target_normal_local.y)
	if not instant:
		proxy.transform.basis = proxy.transform.basis.rotated(proxy.transform.basis.x, target_pitch * ship_statemachine.ship_stats.slerp_speed * delta)
	else:
		proxy.transform.basis = proxy.transform.basis.rotated(proxy.transform.basis.x, target_pitch)

func get_input(delta):
	# turning input
	turn_input = 0.0
	turn_input -= Input.get_action_strength("roll_right")
	turn_input += Input.get_action_strength("roll_left")
	turn_input *= deg_to_rad(turn_force)

	# Brake/Accelerate input
	accel_input = 0.0
	accel_input += Input.get_action_strength("pitch_down")
	accel_input -= Input.get_action_strength("pitch_up")
	
	# if not Input.is_action_pressed("drift"):
	# 	var flags:Dictionary = {
	# 	"target_speed":target_speed,
	# 	"player.velocity":proxy.velocity,
	# 	"forward_speed":forward_speed
	# 	}
	# 	toggle_collision_shapes()
	# 	finished.emit("Rolling", flags)

func toggle_collision_shapes():
	var player_collision_shapes:Array = Array()
	player_collision_shapes.append(%Player/ShipCollider)
	player_collision_shapes.append(%Player/GroundedRayCollider)
	var proxy_collision_shapes:Array = Array()
	proxy_collision_shapes.append(%RollingProxy/Orb/WeBallNow)

	for shapes in player_collision_shapes:
		shapes.disabled = not shapes.disabled
	for shapes in proxy_collision_shapes:
		shapes.disabled = not shapes.disabled
	

func offset_camera_Y(delta:float):
	var _normalized_forward_speed = Helpers.Map(forward_speed, 0, ship_statemachine.ship_stats.hovering_max_speed, 0, 1)
	camera_Y_offset.emit(_normalized_forward_speed, 0, delta)


func _on_orb_body_entered(body:Node) -> void:
	if body.is_in_group("terrain"):
		#print_debug("is grounded setting true, collding with: ")
		if !is_grounded:
			is_grounded = true
			ungrounded_time = ungrounded_grace
		



func _on_orb_body_exited(body:Node) -> void:
	if body.is_in_group("terrain"):
		#print_debug("is grounded setting false, collding with: ")
		is_grounded = false
