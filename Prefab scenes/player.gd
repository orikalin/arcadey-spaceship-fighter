class_name PlayerContainer extends Node


@onready var player:CharacterBody3D = %Player
@onready var mock_camera:Camera3D = %MockCamera
@onready var lookat_target:Node3D = %LookAtTarget

@export var playerTransform:Transform3D
@export var engine_cone_top_rad:float
@export var engine_cone_height:float
@export var trails_scale_min:float
@export var trails_scale_max:float
var spawn_transform:Transform3D


func _ready() -> void:
	if is_multiplayer_authority():
		player.transform = spawn_transform

func get_player() -> CharacterBody3D:
	return player


func get_mock_camera() -> Camera3D:
	return mock_camera


func get_lookat_target() -> Node3D:
	return lookat_target

	
