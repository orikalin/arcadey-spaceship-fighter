extends Node

signal set_spawn_point(Transform3D)
signal spawn_local_player
signal fade_out_in
signal fade_and_load3d(scene_path:String, delete:bool, keep_running:bool)
signal tune_engine_effects(normalized_forward_speed, accel_input)
signal tune_engine_cone_minmax(min:float, max:float)
signal update_speed_ui(speed:float, state_max_speed:float)
signal camera_FOV_control(fov:float, duration:float)

## offsets the camera Z based on the difference in angle between the proxy_orbs forward velocity direction, and the players forward facing direction
signal camera_Z_offset(player:Basis, orb_forward:Vector3)
signal reset_Z_offset
signal set_starting_z

signal ping_sights(near:MeshInstance3D, far:MeshInstance3D)
signal update_sight_ui()
signal sight_lock_change(locked_on:bool)
signal lock_on_break()
signal check_line_of_sight() ## double check line of sight with a simple ray from player to target


