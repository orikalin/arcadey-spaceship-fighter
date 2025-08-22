class_name CameraManager extends Node3D

const CAMERA_MAX_PITCH: float = deg_to_rad(70)
const CAMERA_MIN_PITCH: float = deg_to_rad(-89.9)
const CAMERA_RATIO: float = .625

@export var camera_ease_curve:Curve
@export var z_offset_curve:Curve
@export var mouse_sensitivity: float = .002
@export var mouse_y_inversion: float = -1.0
@export var damping: float = 0.1
@export var ease_speed:float = 1
@export var z_offset_by_angle_max:float = 0.05 ## the target offset to move the camera to when at 180 degrees difference between the player and proxy_orb forward direction

@onready var _camera_yaw: Node3D = self
@onready var _camera_pitch: Node3D = %Arm
@onready var ship_statemachine = %ShipStateMachine
@onready var ship_stats:ShipResource = ship_statemachine.ship_stats
@onready var mock_cam = %MockCamera
@onready var cam_arm:SpringArm3D = %Arm
var phantom_base_cam:PhantomCamera3D
var phantom_drift_cam:PhantomCamera3D
var phantom_free_cam:PhantomCamera3D
var pcam_host_cam:Camera3D
var freeCam:bool = false
var cameraDefaultYaw
var cameraDefaultPitch
var tween_FOV:Tween
signal get_phantom_freecam()
var return_Z_tween:Tween
var starting_z:float = 6.0

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	ship_statemachine.freeCam.connect(toggleFreeCam)
	ship_statemachine.phantom_camera_shift.connect(set_drift_cam_priority)
	for _child:State in ship_statemachine.find_children("*", "State"):
		_child.camera_Y_offset.connect(camera_offset_control)
	SignalHub.camera_FOV_control.connect(camera_FOV_control)
	SignalHub.camera_Z_offset.connect(camera_Z_offset)
	SignalHub.reset_Z_offset.connect(reset_Z_offset)
	# SignalHub.set_starting_z.connect(set_starting_z)
	# starting_z = mock_cam.position.z
	


func toggleFreeCam():
	if freeCam:
		freeCam = false
		phantom_free_cam.set_priority(0)
		_camera_yaw.rotation.y = cameraDefaultYaw
		_camera_pitch.rotation.x = cameraDefaultPitch
	else:
		cameraDefaultYaw = _camera_yaw.rotation.y
		cameraDefaultPitch = _camera_pitch.rotation.x
		freeCam = true
		phantom_free_cam.set_priority(9)


func set_drift_cam_priority(priority:int):
	phantom_drift_cam.set_priority(priority)

func _input(p_event:InputEvent) -> void:
	if !freeCam:
		return
	if p_event is InputEventMouseMotion and Input.get_mouse_mode() == Input.MOUSE_MODE_CAPTURED:
		rotate_camera(p_event.screen_relative)
		get_viewport().set_input_as_handled()
		return


func rotate_camera(p_relative:Vector2) -> void:
	_camera_yaw.rotation.y -= p_relative.x * mouse_sensitivity
	_camera_yaw.orthonormalize()
	_camera_pitch.rotation.x += p_relative.y * mouse_sensitivity * CAMERA_RATIO * mouse_y_inversion 
	_camera_pitch.rotation.x = clamp(_camera_pitch.rotation.x, CAMERA_MIN_PITCH, CAMERA_MAX_PITCH)


func camera_offset_control(EnginePower:float, targetY:float, delta:float):
	if !freeCam:
		var _curve_sample:float = camera_ease_curve.sample(EnginePower)
		phantom_base_cam.follow_offset.y = lerp (phantom_base_cam.follow_offset.y, targetY, _curve_sample * ease_speed * delta)

func camera_FOV_control(_fov:float, _duration:float) -> void:
	if tween_FOV:
		tween_FOV.kill()
	tween_FOV = create_tween()
	tween_FOV.set_trans(Tween.TRANS_CUBIC)
	tween_FOV.set_ease(Tween.EASE_OUT)
	tween_FOV.tween_property(pcam_host_cam, "fov", _fov, _duration)

func camera_Z_offset(player:Basis, orb_forward:Vector3) -> void:
	var _angle_to = orb_forward.angle_to(-player.z)
	_angle_to = rad_to_deg(_angle_to)/180
	var _sample = z_offset_curve.sample(_angle_to)
	var _offset_target = starting_z + z_offset_by_angle_max
	var _new_pos = lerp(starting_z, _offset_target, _sample)
	cam_arm.spring_length = _new_pos

# func camera_Z_offset(player:Basis, orb_forward:Vector3) -> void:
# 	var _angle_to = orb_forward.angle_to(-player.z)
# 	_angle_to = rad_to_deg(_angle_to)/180
# 	var _sample = z_offset_curve.sample(_angle_to)
# 	var _damp = lerp(0.05, 0.0, _sample)
# 	phantom_base_cam.set_follow_damping_value(Vector3(_damp, _damp, _damp))
# 	print_debug(_damp)

func reset_Z_offset(kill_only:bool = false):
	if return_Z_tween:
		return_Z_tween.kill()
	if kill_only:
		return
	return_Z_tween = create_tween().set_ease(Tween.EASE_OUT).set_trans(Tween.TRANS_QUAD)
	return_Z_tween.tween_property(cam_arm,"spring_length", starting_z, 2)
	# print_debug("reset z")


# func set_starting_z():
# 	starting_z = mock_cam.position.z
	
	


		
	
