extends Area3D


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	body_exited.connect(_on_body_exited)


func _on_body_entered(body: Node3D) -> void:
	if body.name == "Player" or "Orb":
		var env: WorldEnvironment = get_node_or_null("../../Environment/WorldEnvironment")
		var gi_light_down:DirectionalLight3D = get_node_or_null("../../Environment/GI_light_down")
		var gi_light_up:DirectionalLight3D = get_node_or_null("../../Environment/GI_light_up") 
		if env:
			var tween: Tween = get_tree().create_tween()
			tween.set_parallel()
			tween.tween_property(env.environment, "ambient_light_energy", .1, .33)
			tween.tween_property(gi_light_down,"shadow_opacity", Global.global_shadow_opacity_dark, .33)
			tween.tween_property(gi_light_up,"shadow_opacity", Global.global_shadow_opacity_dark, .33)			
	

func _on_body_exited(body: Node3D) -> void:
	if body.name == "Player" or "Orb":
		var env: WorldEnvironment = get_node_or_null("../../Environment/WorldEnvironment")
		var gi_light_down:DirectionalLight3D = get_node_or_null("../../Environment/GI_light_down")
		var gi_light_up:DirectionalLight3D = get_node_or_null("../../Environment/GI_light_up")
		if env:
			var tween: Tween = get_tree().create_tween()
			tween.set_parallel()
			tween.tween_property(env.environment, "ambient_light_energy", 1., .33)
			tween.tween_property(gi_light_down,"shadow_opacity", Global.global_shadow_opacity_outside, .33)
			tween.tween_property(gi_light_up,"shadow_opacity", Global.global_shadow_opacity_outside, .33)