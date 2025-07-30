extends Node3D

@onready var NetworkPopup := %NetworkPopup

func _physics_process(delta: float) -> void:	
	if Input.is_action_just_pressed("ui_cancel"):
		NetworkPopup.visible = not NetworkPopup.is_visible()
		if NetworkPopup.is_visible():
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
