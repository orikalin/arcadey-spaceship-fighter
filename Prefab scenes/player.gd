class_name PlayerContainer extends Node


@onready var player:CharacterBody3D = %Player
@onready var mock_camera:Camera3D = %MockCamera
@onready var lookat_target:Node3D = %LookAtTarget

@export var spawn_transform:Transform3D
@export var network_id:int

func _ready() -> void:
	player.transform = spawn_transform
	if multiplayer.multiplayer_peer != null:
		# We should be connected
		assert(network_id != null)


func get_player() -> CharacterBody3D:
	return player


func get_mock_camera() -> Camera3D:
	return mock_camera


func get_lookat_target() -> Node3D:
	return lookat_target

	
