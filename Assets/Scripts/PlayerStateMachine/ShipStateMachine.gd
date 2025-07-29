extends StateMachine

@onready var Player:CharacterBody3D = %Player
signal freeCam()
var correctingRoll:bool = false
@export var rollCorrectionRate:float = 4.0
@export var easeOut:Curve
@export var ShipStats:ShipResource

func _physics_process(delta: float) -> void:	
	if Input.is_action_just_pressed("freeCam"):
		freeCam.emit()
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Input.is_action_just_pressed("headlights"):
		var headlight = $"../ShipContainer/HeadLight"
		headlight.visible = not headlight.visible
	
	if not correctingRoll:
		check_rotation()
	else:
		var targetY:Vector3 = (Vector3.UP - Vector3.UP.dot(-Player.basis.z)*-Player.basis.z).normalized()
		var targetX:Vector3 = (targetY.cross(Player.basis.z)).normalized()
		var targetBasis:Basis = Basis(targetX, targetY, Player.basis.z)
		var targetRotation:Quaternion = Quaternion(targetBasis.orthonormalized())
		var currentRotation:Quaternion = Quaternion(Player.basis.orthonormalized())
		var angleToTarget:float = currentRotation.angle_to(targetRotation)
		var stepAngle:float = rollCorrectionRate * delta
		var stepValue:float = stepAngle/angleToTarget
		var curveSample = easeOut.sample(angleToTarget)
		if stepAngle*curveSample < angleToTarget:
			Player.basis = currentRotation.slerp(targetRotation, stepValue*curveSample)
		else:
			Player.basis = targetBasis
			correctingRoll = false

	super(delta)

func check_rotation():
	var node_up_vector = Player.basis.y
	var angle_to_down_radians = node_up_vector.angle_to(Vector3.DOWN)
	var angle_to_down_degrees = rad_to_deg(angle_to_down_radians)
	var upside_down_threshold = 89

	if angle_to_down_degrees < upside_down_threshold and not Input.is_action_pressed("pitch_down") and not Input.is_action_pressed("pitch_up"):
		correctingRoll = true


