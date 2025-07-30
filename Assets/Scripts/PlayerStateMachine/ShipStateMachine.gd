extends StateMachine

@onready var Player:CharacterBody3D = %Player
@onready var ship_container:MeshInstance3D = %ShipContainer
signal freeCam()
var correctingRoll:bool = false
@export var rollCorrectionRate:float = 4.0
@export var easeOut:Curve
@export var ship_stats:ShipResource

func _physics_process(delta: float) -> void:	
		
	if not is_multiplayer_authority():
		# If we're not in control of this pawn, we should just copy values
		# that have been replicated from the authority
		Player.transform = owner.playerTransform
		ship_container.rotation.z = owner.ship_tilt
		
		# We halt execution so that the state machine doesn't run at all
		# This may not be desireable long term, but it's a useful brute
		# force attempt to prevent players that do not own this pawn from
		# modifying values on this pawn
		return
	
	if Input.is_action_just_pressed("freeCam"):
		freeCam.emit()
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
	
	# After running the state machine, we store some values from it so that
	# information about this pawn taht we own can be replicated to other players
	owner.playerTransform = Player.transform
	owner.ship_tilt = ship_container.rotation.z

func check_rotation():
	var node_up_vector = Player.basis.y
	var angle_to_down_radians = node_up_vector.angle_to(Vector3.DOWN)
	var angle_to_down_degrees = rad_to_deg(angle_to_down_radians)
	var upside_down_threshold = 89

	if angle_to_down_degrees < upside_down_threshold and not Input.is_action_pressed("pitch_down") and not Input.is_action_pressed("pitch_up"):
		correctingRoll = true
