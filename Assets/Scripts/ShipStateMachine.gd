extends StateMachine

func _physics_process(delta: float) -> void:	
	if Input.is_action_just_pressed("freeCam"):
		freeCam.emit()
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	super(delta)



