extends CanvasLayer

@export var sight_one_ui: Sprite2D
@export var sight_two_ui: Sprite2D
@export var anim:AnimationPlayer
@export var far_reticle_speed:float = 10.0
@export var near_reticle_speed:float = 5.0

var main_cam: Camera3D
var sight_one: MeshInstance3D
var sight_two: MeshInstance3D
var one_pos: Vector2
var two_pos: Vector2
var pixel_scaling_multiplier:int = 3

func _ready() -> void:
	SignalHub.ping_sights.connect(set_sights)
	SignalHub.update_sight_ui.connect(update_sight_ui)
	SignalHub.sight_lock_change.connect(lock_on_animate)
	sight_one_ui.hide()
	sight_two_ui.hide()



func _process(delta: float) -> void:
	if !main_cam:
		if Global.main_cam:
			main_cam = Global.main_cam
			sight_one_ui.show()
			sight_two_ui.show()
	update_sight_ui(delta)

	
func update_sight_ui(delta:float):
	if !sight_one or !sight_two:
		return

	one_pos = main_cam.unproject_position(sight_one.global_position)*pixel_scaling_multiplier
	two_pos = main_cam.unproject_position(sight_two.global_position)*pixel_scaling_multiplier

	if !one_pos or !two_pos:
		return

	sight_one_ui.position = lerp(sight_one_ui.position, one_pos, near_reticle_speed*delta)
	sight_two_ui.position = lerp(sight_two_ui.position, two_pos, far_reticle_speed*delta)


func lock_on_animate(locked_on:bool):
	if locked_on:
		anim.play("TARGET_IN_SIGHTS")
	else:
		anim.play("IDLE")


func set_sights(near: MeshInstance3D, far: MeshInstance3D):
	sight_one = near
	sight_two = far
