extends Damageable_Entity
var attacking: bool = false


func _physics_process(delta: float) -> void:
	if !attacking:
		move_along_path(delta)


func _on_detection_range_body_entered(body: Node3D) -> void:
	if body.name == "Player":
		attacking = true
		anim.play("spike_bug_attack")
		await anim.animation_finished
		anim.play("idle")
		attacking = false
