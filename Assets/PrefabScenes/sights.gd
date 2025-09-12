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
## 
## the target swapping implementation involves having VisibleOnScreenNotifier3D on each enemy to add and remove them from the visible_target node group
## then we get a list of visible targets, viability check, and lock on.
## lock should always swap from current target to next furthest target. If no farther target exists, swap to the nearest target.


@export var sight_one: MeshInstance3D
@export var sight_two: MeshInstance3D
@export var sight_raycast: RayCast3D_Signal_Emitter
@export var max_lock_range: float = 360
@export var max_lock_angle: float = 80
@export var max_swap_angle: float = 55
@export var reticle_move_speed: float = 3.0
@export var locked_reticle_move_speed: float = 60.0
@export var los_block_timout: float = 2.0

var sight_two_rest_pos: Vector3 = Vector3(0.0, 0.0, -200.0)
var sight_raycast_rest_pos: Vector3 = Vector3(0.0, 0.0, 0.0)
var locked_on: bool = false
var target_body: Node3D
var locked_on_queue: bool = false
var aim_input: Vector3 = Vector3.ZERO
var los_timer: float = 0.0
var cam_FoV: float = 1.0
var target_swap: bool = false

@onready var player: CharacterBody3D = %Player

func _ready() -> void:
	SignalHub.lock_on_break.connect(lock_on_break)
	SignalHub.camera_FOV_control.connect(store_FoV)


func _physics_process(delta: float) -> void:
	get_input()

	if not locked_on:
		## if target swap was pressed, sort visible targets in order of range from player and attempt to lock on the nearest one
		if target_swap:
			target_swap = false
			var visible_targets: Array = get_tree().get_nodes_in_group("visible_target")
			if visible_targets:
				visible_targets.sort_custom(_sort_by_distance)
				for target in visible_targets:
					if target.is_in_group("targetable"):
						var distance_from_player: float = target.global_position.distance_to(player.global_position)
						if distance_from_player < max_lock_range:
							if is_within_max_angle(target, max_swap_angle):
								lock_on_target(target)
								return

			
		## move reticle tracker based on input values, or return to rest when there is no input
		var target_rest_pos: Vector3 = Vector3.ZERO
		if aim_input == Vector3.ZERO:
			target_rest_pos = sight_two_rest_pos
			sight_raycast.rotation = sight_raycast_rest_pos
		else:
			target_rest_pos = sight_two_rest_pos + (aim_input * reticle_move_speed)
			sight_raycast.look_at(to_global(target_rest_pos), sight_raycast.global_basis.y)

		sight_two.transform.origin = target_rest_pos

		## if a targetable is detected, initiate lock on viability check
		var _sight_raycast_target = sight_raycast.get_collider() as Node3D
		if _sight_raycast_target:
			if _sight_raycast_target.is_in_group("targetable"):
				lock_on_target(_sight_raycast_target)
		else:
			return

	if target_body:
		## if target swap was pressed, sort visible targets in order of range from player and attempt to lock on the nearest one
		if target_swap:
			target_swap = false
			var visible_targets: Array = get_tree().get_nodes_in_group("visible_target")
			if !visible_targets.is_empty():
				visible_targets.sort_custom(_sort_by_distance)
				var i: int = 0
				for target in visible_targets:
					if target.is_in_group("targetable"):
						var distance_from_player: float = target.global_position.distance_to(player.global_position)
						if distance_from_player > target_body.global_position.distance_to(player.global_position):
							if distance_from_player < max_lock_range:
								if is_within_max_angle(target, max_swap_angle):
									lock_on_target(target)
									if target_body:
										return
						elif i == visible_targets.size() - 1:
							if is_within_max_angle(target, max_swap_angle):
								lock_on_target(visible_targets[0])
								return
					i += 1


		if target_body.global_position.distance_to(global_position) > max_lock_range or !is_within_max_angle(target_body, max_lock_angle):
			lock_on_break()
			return
		
		# Apply inputs to the targetting position
		var target_final_pos: Vector3 = Vector3.ZERO
		if (aim_input == Vector3.ZERO):
			target_final_pos = to_local(target_body.global_position)
		else:
			target_final_pos += to_local(target_body.global_position) + (aim_input * locked_reticle_move_speed)
			pass
		

		sight_two.transform.origin = target_final_pos
		sight_raycast.look_at(to_global(target_final_pos), get_parent().global_rotation)

		if is_line_of_sight_blocked(target_body):
			if los_timer < los_block_timout:
				los_timer += delta
			else:
				lock_on_break()
		else:
			los_timer = 0


func get_input() -> void:
	aim_input = Vector3.ZERO
	aim_input.x += (Input.get_action_strength("r_stick_right") + -Input.get_action_strength("r_stick_left")) * 1.5 * cam_FoV
	aim_input.y += Input.get_action_strength("r_stick_up") + -Input.get_action_strength("r_stick_down") * cam_FoV
	if Input.is_action_just_pressed("target_swap"):
		target_swap = true
		

# eventually, add a bool to all valid target classes for is_targetable
func _on_sight_soft_locker_body_entered(body: Node3D) -> void:
	if !locked_on:
		if body.is_in_group("targetable"):
			lock_on_target(body)
		

func lock_on_target(body: Node3D) -> void:
	if not is_line_of_sight_blocked(body):
		locked_on = true
		target_body = body
		SignalHub.sight_lock_change.emit(locked_on)


func lock_on_break() -> void:
	locked_on = false
	target_body = null
	sight_two.transform.origin = sight_two_rest_pos
	sight_raycast.rotation = sight_raycast_rest_pos
	SignalHub.sight_lock_change.emit(locked_on)


func is_line_of_sight_blocked(body: Node3D) -> bool:
	var space_state = get_world_3d().direct_space_state
	var query = PhysicsRayQueryParameters3D.new()
	query.collide_with_bodies = true
	query.collision_mask = 1
	query.from = %Player.global_position
	query.to = body.global_position

	var result = space_state.intersect_ray(query)
	if result:
		if not result.collider.is_in_group("targetable"):
			return true # ray hit terrain
		else:
			return false
	else:
		return false


func is_within_max_angle(body: Node3D, max_angle: float) -> bool:
	# get the difference in angle between the players forward and the target_body position.
	var _local_forward = - global_basis.z
	var _direction_to = (body.global_position - global_position).normalized()
	var _angle_to = rad_to_deg(acos(_local_forward.dot(_direction_to)))
	if _angle_to < max_angle:
		return true
	else:
		return false


func store_FoV(_fov: float, _duration: float) -> void:
	cam_FoV = _fov * 0.01 + 0.25


func _sort_by_distance(a, b) -> bool:
	var player_pos = player.global_position
	var distance_a = a.global_position.distance_to(player_pos)
	var distance_b = b.global_position.distance_to(player_pos)
	return distance_a < distance_b
