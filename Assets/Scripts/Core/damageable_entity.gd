class_name Damageable_Entity extends Node3D

@export_category("Refs")
@export var path: PathFollow3D
@export var body:Node3D
@export var shape_keyed_mesh: MeshInstance3D
@export var anim: AnimationPlayer
@export var hitbox: Area3D
@export var hurtbox: Area3D

@export_category("Common var")
@export var max_health: int = 0
@export var max_shield: int = 0
@export var move_speed: float = 0.0
@export var base_damage: int = 40

var _time: float = 0.0

var health: int:
    set(value):
        if value > max_health:
            health = max_health
        else:
            health = value
    get:
        return health

var shield: int:
    set(value):
        if value > max_shield:
            shield = max_shield
        else:
            shield = value
    get:
        return health

func move_along_path(delta: float) -> void:
    path.progress_ratio += delta * move_speed
    # _time += delta * move_speed
    # var osc_value = (sin(_time) +1.0) * 0.5
    # path.progress_ratio = osc_value
    # var invert: bool = false
    # if invert:
    #     path.progress_ratio -= delta * move_speed
    # else:
    #     path.progress_ratio += delta * move_speed

    # if path.progress_ratio == 1.0:
    #     invert = true
    # elif path.progress_ratio == 0.0:
    #     invert = false