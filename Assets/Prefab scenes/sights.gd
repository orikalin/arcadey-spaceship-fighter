extends Node3D

## The idea I'm having is to make two cones, and a raycast3D that checks for interuptions in line of sight
## these cone shape colliders will start at the player origin, and do not move or rotate locally
## the small cone will act as a target acquierer. it can auto send out signals on body enter, at which point a ray will be cast towards to target
## to see if any terrain or other obstacles are in the way. If not, we soft lock to that target.
##
## the larger cone is a lock-on limit. if the far sight leaves the large cone, the lock will be broken
## the large cone and far sight have collide exlusively with eachother
## the small cone collides with only viable targets
## and the raycast colliders with terrain. Can save some work maybe by only allowing the lock on to happen if the ray collision (first collision)
## isn't terrain and is a viable target

@export var sight_one:MeshInstance3D
@export var sight_two:MeshInstance3D
@export var sight_raycast:RayCast3D_Signal_Emitter
@export var max_lock_range:float = 360
@export var max_lock_angle:float = 80
@export var reticle_move_speed:float = 3.0
@export var locked_reticle_move_speed:float = 60.0
var sight_two_rest_pos:Vector3 = Vector3(0.0, 0.0, -200.0)
var sight_raycast_rest_pos:Vector3 = Vector3(0.0, 0.0, 0.0)
var locked_on:bool = false
var target_body:Node3D
var locked_on_queue:bool = false
var aim_input:Vector3 = Vector3.ZERO

func _ready() -> void:
	SignalHub.lock_on_break.connect(lock_on_break)


func _physics_process(delta: float) -> void:
	get_input()

	if not locked_on:
		# move reticle tracker based on input values
		var target_rest_pos:Vector3 = Vector3.ZERO
		if aim_input == Vector3.ZERO:
			target_rest_pos = sight_two_rest_pos
			sight_raycast.rotation = sight_raycast_rest_pos
		else:
			target_rest_pos = sight_two_rest_pos + (aim_input * reticle_move_speed)
			sight_raycast.look_at(to_global(target_rest_pos), get_parent().global_rotation)

		sight_two.transform.origin = target_rest_pos
		return

	if target_body:	
		# get the difference in angle between the players forward and the target_body position.
		var _local_forward = -global_basis.z
		var _direction_to = (target_body.global_position - global_position).normalized()
		var _angle_to = rad_to_deg(acos(_local_forward.dot(_direction_to)))
		if target_body.global_position.distance_to(global_position) > max_lock_range or _angle_to > max_lock_angle:
			lock_on_break()
			return
		
		# Apply inputs to the targetting position
		var target_final_pos:Vector3 = Vector3.ZERO
		if (aim_input == Vector3.ZERO):
			target_final_pos = to_local(target_body.global_position)
		else:
			target_final_pos += to_local(target_body.global_position) + (aim_input * locked_reticle_move_speed)
			pass
		

		sight_two.transform.origin = target_final_pos
		sight_raycast.look_at(to_global(target_final_pos), get_parent().global_rotation)
	else:
		lock_on_break()


func get_input() -> void:
	aim_input = Vector3.ZERO
	aim_input.x += Input.get_action_strength("r_stick_right") + -Input.get_action_strength("r_stick_left")
	aim_input.y += Input.get_action_strength("r_stick_up") + -Input.get_action_strength("r_stick_down")

func _on_sight_soft_locker_body_entered(body:Node3D) -> void:
	print_debug(body.name, " entered soft lock area")
	if !locked_on:
		locked_on = true
		target_body = body
		SignalHub.sight_lock_change.emit(locked_on)
	# eventually, add a bool to all valid target classes for is_targetable
		


# func _on_sight_lock_limit_area_exited(area:Area3D) -> void:
# 	lock_on_break()

# func _on_sight_lock_limit_area_entered(area: Area3D) -> void:
# 	lock_on_break()

func lock_on_break():
	locked_on = false
	target_body = null
	sight_two.transform.origin = sight_two_rest_pos
	sight_raycast.rotation = sight_raycast_rest_pos
	SignalHub.sight_lock_change.emit(locked_on)
