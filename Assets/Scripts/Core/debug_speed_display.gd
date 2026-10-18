extends RichTextLabel



func _ready() -> void:
	SignalHub.update_speed_ui.connect(update_speed_ui)


func update_speed_ui(speed:float, state_max_speed:float, accel_input:float, slide_boost_power:float = 0.0, current_state:String = ""):
	var formated_accel_input = "%.2f" % accel_input
	var formated_slide_boost_power = "%.2f" % slide_boost_power
	self.bbcode_text = current_state + "\n" + str(formated_slide_boost_power) + "\n" +  str(formated_accel_input) + "\n" + str(int(speed))
