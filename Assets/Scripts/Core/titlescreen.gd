extends Control

@export var intro_level:PackedScene
@export var player_ui:PackedScene
			

func _on_single_player_pressed() -> void:
	SignalHub.fade_and_load3d.emit(intro_level.resource_path, true, false)
	Global.scene_manager.change_gui_scene(player_ui.resource_path, true, false)
	#Global.scene_manager.change_3d_scene(intro_level.resource_path, true, false)



func _on_multiplayer_pressed() -> void:
	pass # Replace with function body.
