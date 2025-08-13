extends Node

signal set_spawn_point(Transform3D)
signal spawn_local_player
signal fade_out_in
signal fade_and_load3d(scene_path:String, delete:bool, keep_running:bool)
signal tune_engine_effects(normalized_forward_speed, accel_input)
signal tune_engine_cone_minmax(min:float, max:float)
signal update_speed_ui(speed:float, state_max_speed:float)
signal camera_FOV_control(fov:float, duration:float)


