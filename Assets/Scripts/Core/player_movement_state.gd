class_name PlayerMovementState extends State

@export var lock_accel_input:bool = false

var gamepad: bool = false
var accel_held: bool = false
var is_grounded: bool = false
var average_terrain_normal: Vector3
var turn_input: float = 0.0
var pitch_input: float = 0.0
var accel_input: float = 0.0
var gravity_tween: Tween
var current_air_gravity:float
var gravity_increase: float
var current_impulse: int = 0

@onready var player: CharacterBody3D = %Player
@onready var proxy_xform: CharacterBody3D = %PlayerProxy
@onready var proxy_orb: RigidBody3D = %Orb
@onready var ship_state_machine:StateMachine = self.get_parent()
@onready var ship_stats:Resource = ship_state_machine.ship_stats
@onready var physics_material := PhysicsMaterial.new() ## Generated @onready for use in this state machine
@onready var ground_raycasts: Array = %ground_check_rays.get_children()
@onready var down_slope_ray: RayCast3D = %down_slope_check


func update(delta: float):
	if not is_grounded and gravity_increase < 8.0:
		gravity_increase += delta * ship_stats.gravity_increase_rate
	else:
		gravity_increase = 0.0


# This function imposes a hard limit on the Rigidybody3D's physics state's max speed
# considering removing this, and increasing the linear damping to get a similar effect
# that lets gravity better work movement forces
# will require its own branch and lots of testing
func _integrate_forces(state):
	var _current_velocity = state.linear_velocity
	var _speed = _current_velocity.length()

	# if _speed > ship_stats.state_max_speed:
	# 	state.linear_velocity = _current_velocity.normalized() * ship_stats.state_max_speed


# check the 5 raycasts, get the average normal of all terrain hit, return true if any rays hit terrain
# additionally, checks a farther forward down raycast for early detection of slopes ahead of player,
# though this ray is not considered for is_grounded

# add a way to delay a false return by checking if there is ground within a reasonable distance below the ship
# if not, return false
func check_ground_normals() -> bool:
	var _terrain_normals: Array
	var _sum_terrain_normals := Vector3.ZERO
	var down_slope_normal := Vector3.ZERO
	

	for raycast: RayCast3D in ground_raycasts:
		var _raycast_hit := raycast.get_collider() ## the object returned by the ground check raycast
		if _raycast_hit != null:
			if _raycast_hit.get_collision_mask_value(1):
				_terrain_normals.append(raycast.get_collision_normal())

	down_slope_normal = down_slope_ray.get_collision_normal() # This is not included when considering if the player is grounded
	
	var _terrain_normals_size: int = _terrain_normals.size()

	if _terrain_normals_size > 0:
		for _normal in _terrain_normals:
			_sum_terrain_normals += _normal

		if down_slope_normal != Vector3.ZERO:
			average_terrain_normal = (_sum_terrain_normals + down_slope_normal) / (_terrain_normals_size + 1)
		else:
			average_terrain_normal = _sum_terrain_normals / _terrain_normals_size

		return true
	else:
		return false
		

# simple check for gamepad use
func _input(event: InputEvent) -> void:
	if event is InputEventKey or event is InputEventMouse:
		gamepad = false
	elif event is InputEventJoypadMotion or event is InputEventJoypadButton:
		gamepad = true

# common movement related inputs
func get_input(delta: float) -> void:
	turn_input = 0.0
	turn_input -= Input.get_action_strength("roll_right")
	turn_input += Input.get_action_strength("roll_left")
	
	pitch_input = 0.0
	pitch_input += Input.get_action_strength("r_stick_up")
	pitch_input -= Input.get_action_strength("r_stick_down")

	# Adjust the speed at which the input value changes with accel_multiplier
	# accel_held is mostly deprecated, but is essential for a commented out function in rolling.gd
	# I want to eventually implement the behaviour change as a toggleable option
	# That being, "Keep Acceleration Strength?"
	# Turning this off results in acceleration strength decaying over time when no input is held
	# Turning this on results in acceleration strength staying at its current strength value, essentially auto-accel
	# or as an accesability option to remedy having to hold the left stick up for long periods of time
	if lock_accel_input:
		pass

	else:
		if Input.is_action_pressed("throttle_up"):
			if accel_input < 1:
				accel_input += delta * ship_stats.accel_multiplier

			else:
				accel_input = 1

			accel_held = true

		elif Input.get_action_strength("throttle_down") > 0.5:
			if accel_input > -0.4:
				accel_input -= delta * ship_stats.accel_multiplier

			else:
				accel_input = -0.4

			accel_held = true

		else:
			if accel_input < 0.0 or accel_input < 0.15:
				accel_input = 0.0

			accel_held = false
