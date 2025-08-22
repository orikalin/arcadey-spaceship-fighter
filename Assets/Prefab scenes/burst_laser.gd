extends Node3D

@export var spawn_point:Node3D
@export var burst_interval:float = 0.15
@export var cooldown:float = 0.8
@export var bullet:PackedScene
var cooldown_timer:float = 0.0


func _process(delta: float) -> void:
	if Input.is_action_pressed("fire1") and cooldown_timer <= 0.0:
		x_round_burst(3)
		cooldown_timer = cooldown

	if cooldown_timer > 0.0:
		cooldown_timer -= delta
	

func x_round_burst(count:int):
	var _shots_fired := 0
	cooldown_timer = cooldown
	while _shots_fired < count:
		var _instance = bullet.instantiate()
		owner.add_child(_instance)
		_instance.global_position = spawn_point.global_position
		_instance.global_basis = %sight_raycast.global_basis
		_shots_fired += 1
		await get_tree().create_timer(burst_interval).timeout
