class_name PlayerContainer extends Node


@onready var player:CharacterBody3D = %Player
@onready var mock_camera:Camera3D = %MockCamera
@onready var lookat_target:Node3D = %LookAtTarget

#store values for synchronization with other players
@export var playerTransform:Transform3D
@export var engine_cone_top_rad:float
@export var engine_cone_height:float
@export var trails_scale_min:float
@export var trails_scale_max:float
@export var light_energy_spot:float
@export var light_energy_omni:float
@export var light_attenuation:float
@export var ship_tilt:float

var spawn_transform:Transform3D


func _ready() -> void:	
	if is_multiplayer_authority():
		# if we own this pawn, we update our transform to match the spawn transform
		player.transform = spawn_transform

func get_player() -> CharacterBody3D:
	return player


func get_mock_camera() -> Camera3D:
	return mock_camera


func get_lookat_target() -> Node3D:
	return lookat_target

	
