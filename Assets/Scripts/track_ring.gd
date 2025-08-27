extends Node3D

@onready var anim:AnimationPlayer = %AnimationPlayer
var collected:bool = false
var player

func _ready():
	anim.play("IDLE")

func _physics_process(delta: float) -> void:
	if collected:
		global_position = player.global_position


func _on_area_3d_body_entered(body:Node3D) -> void:
	if body.name == "Orb" or body.name == "Player":
		player = body
		%CollisionShape3D.disabled = true
		anim.play("COLLECT")
		collected = true
		print_debug(body.name)
		await anim.animation_finished
		print_debug("finished")
		queue_free()
