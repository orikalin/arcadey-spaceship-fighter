extends RichTextLabel



func _ready() -> void:
	SignalHub.update_speed_ui.connect(update_speed_ui)


func update_speed_ui(speed:float, state_max_speed:float, accel_input:float):
	self.bbcode_text = str(accel_input) + "\n" + str(int(speed)) + " / " + str(int(state_max_speed))
