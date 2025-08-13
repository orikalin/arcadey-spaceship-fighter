extends RichTextLabel



func _ready() -> void:
    SignalHub.update_speed_ui.connect(update_speed_ui)


func update_speed_ui(speed:float, state_max_speed):
    self.bbcode_text = str(int(speed)) + " / " + str(int(state_max_speed))