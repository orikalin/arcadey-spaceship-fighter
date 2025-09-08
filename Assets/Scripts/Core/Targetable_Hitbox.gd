extends Area3D

@onready var notifier:VisibleOnScreenNotifier3D = $VisibleOnScreenNotifier3D

func _process(delta) -> void:
	if notifier.is_on_screen():
		if !is_in_group("visible_target"):
			add_to_group("visible_target")
	else:
		if is_in_group("visible_target"):
			remove_from_group("visible_target")
