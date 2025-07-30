extends Node

@export var spawn_transform:Transform3D
@onready var player:CharacterBody3D = %Player
@onready var mock_camera:Camera3D = %MockCamera
@onready var lookat_target:Node3D = %LookAtTarget

func _ready() -> void:
	print_debug("are we ready?")
	player.transform = spawn_transform


func get_player() -> CharacterBody3D:
	return player




func get_mock_camera() -> Camera3D:
	return mock_camera


func get_lookat_target() -> Node3D:
	return lookat_target

	
