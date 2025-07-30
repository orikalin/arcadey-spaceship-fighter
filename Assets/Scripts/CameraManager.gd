class_name CameraManager extends Node3D

const CAMERA_MAX_PITCH: float = deg_to_rad(70)
const CAMERA_MIN_PITCH: float = deg_to_rad(-89.9)
const CAMERA_RATIO: float = .625

@export var mouse_sensitivity: float = .002
@export var mouse_y_inversion: float = -1.0
@export var damping: float = 0.1

@onready var _camera_yaw: Node3D = self
@onready var _camera_pitch: Node3D = %Arm
@onready var ShipStateMachine = get_node("../ShipStateMachine")
@onready var MockCam = %MockCamera
var phantom_base_cam:PhantomCamera3D
var phantom_free_cam:PhantomCamera3D
var freeCam:bool = false
var cameraDefaultYaw
var cameraDefaultPitch

signal get_phantom_freecam()

func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)
	ShipStateMachine.freeCam.connect(toggleFreeCam)

# func _process(delta: float) -> void:
# 	if !freeCam: 
# 		MainCam.transform.position = lerp(MainCam.transform.position, MockCam.transform.position, damping)

func toggleFreeCam():
	if phantom_free_cam == null:
		assert(phantom_free_cam != null, "phantom free cam is still null")
	if freeCam:
		freeCam = false
		phantom_free_cam.priority = 0
		_camera_yaw.rotation.y = cameraDefaultYaw
		_camera_pitch.rotation.x = cameraDefaultPitch
	else:
		cameraDefaultYaw = _camera_yaw.rotation.y
		cameraDefaultPitch = _camera_pitch.rotation.x
		freeCam = true
		phantom_free_cam.priority = 2

func _input(p_event: InputEvent) -> void:
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
