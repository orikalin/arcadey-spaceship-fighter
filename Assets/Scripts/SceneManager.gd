class_name SceneManager extends Node

@export var world_3d:Node3D
@export var world_2d:Node2D
@export var gui:Control

var current_3d_scene
var current_2d_scene
var current_gui_scene


func _ready() -> void:
    Global.scene_manager = self
    current_gui_scene = $GUI/SplashScreenManager
    get_tree()


func change_gui_scene(new_scene:String, delete:bool = true, keep_running:bool = false)->void:
    if current_gui_scene != null:
        if delete:
            current_gui_scene.queue_free() # Removes node entirely
        elif keep_running:
            current_gui_scene.visible = false # Keeps in memory and running
        else:
            gui.remove_child(current_gui_scene) # Keeps in memory, does not run. Data may be stale.
    var new = load(new_scene).instantiate()
    gui.add_child(new)
    current_gui_scene = new


func change_3d_scene(new_scene:String, delete:bool = true, keep_running:bool = false)->void:
    if current_3d_scene != null:
        if delete:
            current_3d_scene.queue_free() # Removes node entirely
        elif keep_running:
            current_gui_scene.visible = false # Keeps in memory and running
        else:
            gui.remove_child(current_3d_scene) # Keeps in memory, does not run. Data may be stale.
    var new = load(new_scene).instantiate()
    gui.add_child(new)
    current_3d_scene = new
