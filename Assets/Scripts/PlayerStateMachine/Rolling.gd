extends State

@export var player:CharacterBody3D
@export var proxy:RigidBody3D
@export var ShipContainer:MeshInstance3D
@export var floor_raycast:RayCast3D
@export var falling_damping_curve:Curve
@export var easeOut:Curve

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
@export var gravity_airborne:float = 4.0
@export var gravity_grounded:float = 1.0
@export var ground_stick_force:float = 50.0
@export var max_normal_alignment:float = 0.0
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

	# access the physics server directly for detailed contact information
	var physics_state = PhysicsServer3D.body_get_direct_state(proxy.get_rid())
	var contact_count = physics_state.get_contact_count()

	var average_terrain_normal:Vector3

	# check contact count to determine if grounded
	if contact_count > 0:
		if contact_count > 1:
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
		var xform = align_with_y(player.global_transform, average_terrain_normal.normalized())

		var relative_xform = player.global_basis.inverse() * xform.basis

		var _player_quat:Quaternion = Quaternion(player.basis.orthonormalized())
		var _target_quat:Quaternion = Quaternion(xform.basis.orthonormalized())
		var angle_to_target:float = rad_to_deg(_player_quat.angle_to(_target_quat))


		print_debug(angle_to_target)
		# if statement checking angle_to_target vs max terrain angle
		if angle_to_target < max_normal_alignment:
			player.global_transform = player.global_transform.interpolate_with(xform, rolling_level_speed * delta)
			player.global_transform = player.global_transform.orthonormalized()
		elif angle_to_target > max_normal_alignment and check_rotation():
			correct_roll(delta)



		proxy.gravity_scale = gravity_grounded
		proxy.apply_central_force(-average_terrain_normal * ground_stick_force)
		proxy.apply_central_force(-player.basis.z * accel_force * accel_input)
	else:
		proxy.gravity_scale = gravity_airborne
		proxy.apply_central_force(-player.basis.z * accel_force * accel_input * 0.25)
	
	player.transform.origin = proxy.transform.origin
	player.global_transform = player.global_transform.orthonormalized()

	# turn ship
	if proxy.linear_velocity.length() > turn_stop_limit:
		var new_basis = player.global_transform.basis.rotated(player.global_basis.y, turn_input)
		player.global_basis = player.global_basis.slerp(new_basis, turn_force * delta)
		player.global_transform = player.global_transform.orthonormalized()

	# else:
		# ShipContainer.global_transform = ShipContainer.global_transform.interpolate_with(player.transform, rolling_level_speed * 0.5 * delta)
		# if ungrounded_time <= 0.0:
		# 	proxy.gravity_scale = gravity_airborne
		# else:
		# 	ungrounded_time -= delta
	#player.transform = player.global_transform.interpolate_with(ShipContainer.global_transform, rolling_level_speed * delta)



func align_with_y(xform, new_y):
	xform.basis.y = new_y
	xform.basis.x = -xform.basis.z.cross(new_y)
	xform.basis = xform.basis.orthonormalized()
	return xform

func check_rotation() -> bool:
	var node_up_vector = player.basis.y
	var angle_to_down_radians = node_up_vector.angle_to(Vector3.DOWN)
	var angle_to_down_degrees = rad_to_deg(angle_to_down_radians)
	var upside_down_threshold = 89

	if angle_to_down_degrees < upside_down_threshold:
		return true
	else:
		return false


func correct_roll(delta:float):
	var targetY:Vector3 = (Vector3.UP - Vector3.UP.dot(-player.basis.z)*-player.basis.z).normalized()
	var targetX:Vector3 = (targetY.cross(player.basis.z)).normalized()
	var targetBasis:Basis = Basis(targetX, targetY, player.basis.z)
	var targetRotation:Quaternion = Quaternion(targetBasis.orthonormalized())
	var currentRotation:Quaternion = Quaternion(player.basis.orthonormalized())
	var angleToTarget:float = currentRotation.angle_to(targetRotation)
	var stepAngle:float = rolling_level_speed * delta
	var stepValue:float = stepAngle/angleToTarget
	var curveSample = easeOut.sample(angleToTarget)
	if stepAngle*curveSample < angleToTarget:
		player.basis = currentRotation.slerp(targetRotation, stepValue*curveSample)
	else:
		player.basis = targetBasis


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
