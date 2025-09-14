class_name PlayerMovementState extends State

@onready var player: CharacterBody3D = %Player
@onready var proxy_xform: CharacterBody3D = %PlayerProxy
@onready var proxy_orb: RigidBody3D = %Orb
@onready var ship_state_machine = self.get_parent()
@onready var ship_stats = ship_state_machine.ship_stats
@onready var physics_material := PhysicsMaterial.new()
@onready var ground_raycasts: Array = %ground_check_rays.get_children()

var average_terrain_normal

## This function imposes a hard limit on the Rigidybody3D's physics state's max speed
## considering removing this, and increasing the linear damping to get a similar effect
## will require its own branch and lots of testing
func _integrate_forces(state):
	var _current_velocity = state.linear_velocity
	var _speed = _current_velocity.length()

	if _speed > ship_stats.state_max_speed:
		state.linear_velocity = _current_velocity.normalized() * ship_stats.state_max_speed

## check the 5 raycasts, get the average normal of all terrain hit, return true if any rays hit terrain
func check_ground() -> bool:
	var _terrain_normals: Array
	var _sum_terrain_normals := Vector3.ZERO

	for raycast: RayCast3D in ground_raycasts:
		var _raycast_hit := raycast.get_collider()
		if _raycast_hit != null:
			if _raycast_hit.get_collision_mask_value(1):
				_terrain_normals.append(raycast.get_collision_normal())

	var _terrain_normals_size: int = _terrain_normals.size()

	if _terrain_normals_size > 0:
		for _normal in _terrain_normals:
			_sum_terrain_normals += _normal

		average_terrain_normal = _sum_terrain_normals / _terrain_normals_size

		return true
	else:
		return false
		

# func get_input(delta:float) -> void:
#     	# turning input
# 	turn_input = 0.0
# 	turn_input -= Input.get_action_strength("roll_right")
# 	turn_input += Input.get_action_strength("roll_left")
# 	turn_input *= deg_to_rad(ship_stats.rolling_turn_force)

# 	if Input.is_action_pressed("throttle_up"):
# 		if accel_input < 1:
# 			accel_input += delta * accel_multiplier
# 		else:
# 			accel_input = 1
# 		accel_held = true

# 	elif Input.is_action_pressed("throttle_down"):
# 		accel_input = -0.4
# 		accel_held = true
# 	else:
# 		accel_held = false
	
# 	if Input.is_action_pressed("drift") and is_grounded:
# 		var flags:Dictionary = {
# 		"forward_speed":forward_speed,
# 		"accel_input":accel_input
# 		}
# 		finished.emit("drift", flags)

# 	elif Input.is_action_pressed("boost") and ship_stats.boost_fuel_current > 0.001:
# 		var flags:Dictionary = {
# 		"forward_speed":forward_speed
# 		}
# 		finished.emit("boost", flags)
	
# 	pitch_input = 0.0
# 	pitch_input += Input.get_action_strength("r_stick_up")
# 	pitch_input -= Input.get_action_strength("r_stick_down")