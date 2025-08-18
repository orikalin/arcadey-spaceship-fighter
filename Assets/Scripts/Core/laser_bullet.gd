extends CharacterBody3D

@export var speed:float = 40 
@export var lifetime:float = 5.0
@export var max_energy:float = 0.2
@export var energy_multiplier:float = 1.0
@onready var raycast:RayCast3D = $RayCast3D
@onready var particles = $GPUParticles3D
@onready var mesh = $MeshInstance3D
@onready var light:OmniLight3D = $OmniLight3D



func _process(delta):
	if light.light_energy < max_energy:
		light.light_energy += delta * energy_multiplier
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	position += transform.basis * Vector3.FORWARD * speed * delta
	if raycast.is_colliding():
		mesh.visible = false
		particles.emitting = true
		await get_tree().create_timer(1.0).timeout
		queue_free()
