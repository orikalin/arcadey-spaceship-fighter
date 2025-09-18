extends CharacterBody3D

@export var speed:float = 40 
@export var lifetime:float = 5.0
@export var max_energy:float = 0.2
@export var energy_multiplier:float = 1.0
@export var light_diss_curve:Curve
@onready var raycast:RayCast3D = $RayCast3D
@onready var particles = $GPUParticles3D
@onready var light:OmniLight3D = $OmniLight3D
@onready var meshes:Array
var tween:Tween

func _ready():
	meshes = $Meshes.get_children()

func _process(delta):
	if meshes[0].visible == false:
		if tween: 
			pass
		else:
			tween = create_tween()
			tween.tween_method(func(progress):
				var curve_val = light_diss_curve.sample(progress)
				light.light_energy = lerp(1.0, 0.0, curve_val), 0.0, 1.0, 1.0)
	elif light.light_energy < max_energy:
		light.light_energy += delta * energy_multiplier
	await get_tree().create_timer(lifetime).timeout
	queue_free()

func _physics_process(delta: float) -> void:
	if raycast.enabled:
		if raycast.is_colliding():
			for mesh in meshes:
				mesh.visible = false
			particles.emitting = true
			raycast.enabled = false
			await get_tree().create_timer(1.0).timeout
			tween.kill()
			queue_free()
		else:
			position += transform.basis * Vector3.FORWARD * speed * delta
