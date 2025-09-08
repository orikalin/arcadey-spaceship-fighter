class_name Damageable_Entity extends Node3D

@export var max_health:float = 0.0
@export var max_shield:float = 0.0


var health:float:
    set(value):
        if value > max_health:
            health = max_health
        else:
            health = value
    get:
        return health

var shield:float:
    set(value):
        if value > max_shield:
            shield = max_shield
        else:
            shield = value
    get:
        return health



func _ready():
    pass


func _process(delta: float) -> void:
    pass
