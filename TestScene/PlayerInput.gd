extends CharacterBody3D

signal throttleUp()
signal throttleDown()
signal rollLeft(strength: float)
signal rollRight(strength: float)
signal pitchUp(strength: float)
signal pitchDown(strength: float)
signal shoot1()
signal shoot2()


func _physics_process(delta):
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Input.is_action_pressed("throttle_up"):
		throttleUp.emit()
	if Input.is_action_pressed("throttle_down"):
		throttleDown.emit()
	if Input.is_action_pressed("roll_left"):
		rollLeft.emit(Input.get_action_strength("roll_left"))
	if Input.is_action_pressed("roll_right"):
		rollRight.emit(Input.get_action_strength("roll_right"))
	if Input.is_action_pressed("pitch_up"):
		pitchUp.emit(Input.get_action_strength("pitch_up"))
	if Input.is_action_pressed("pitch_down"):
		pitchDown.emit(Input.get_action_strength("pitch_down"))
	if Input.is_action_pressed("shoot1"):
		shoot1.emit()
	if Input.is_action_pressed("shoot2"):
		shoot2.emit()
