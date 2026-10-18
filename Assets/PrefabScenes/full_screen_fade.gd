extends ColorRect

@export var in_time : float = 0.5
@export var fade_in_time : float = .25
@export var pause_time : float = 0.5
@export var fade_out_time : float = 1
@export var out_time : float = 0.5
@export var splash_screen_container : Node

var _scene_path:String
var _delete:bool
var _keep_running:bool


func _ready():
	SignalHub.fade_out_in.connect(fade)
	SignalHub.fade_and_load3d.connect(fade_and_load_3d)

func fade():
	var tween := self.create_tween()
	tween.tween_interval(in_time)
	tween.tween_property(self, "modulate:a", 1.0, fade_in_time)
	tween.tween_interval(pause_time)
	tween.tween_property(self, "modulate:a", 0.0, fade_in_time)
	tween.tween_interval(out_time)
	await tween.finished


func fade_and_load_3d(scene_path:String, delete:bool = true, keep_running:bool = false):
	_scene_path = scene_path
	_delete = delete
	_keep_running = keep_running
	var tween := self.create_tween()
	tween.tween_interval(in_time)
	tween.tween_property(self, "modulate:a", 1.0, fade_in_time)
	tween.tween_interval(pause_time)
	tween.tween_callback(_tween_callback_load_level)
	tween.tween_interval(pause_time)
	tween.tween_callback(_tween_callback_spawn_player)
	tween.tween_property(self, "modulate:a", 0.0, fade_in_time)
	tween.tween_interval(out_time)
	await tween.finished

func _tween_callback_load_level():
	Global.scene_manager.change_3d_scene(_scene_path, _delete, _keep_running)

func _tween_callback_spawn_player():
	SignalHub.spawn_local_player.emit()