extends Node

# Core functionality signals
signal set_spawn_point(Transform3D) ## Updates the spawn point of the player based on the loaded maps spawn point
signal spawn_local_player ## spawns the local player and connects the phantom cameras to them
signal fade_out_in
signal fade_and_load3d(scene_path:String, delete:bool, keep_running:bool)

# Ship VFX signals
signal tune_engine_effects(normalized_forward_speed, accel_input) ## Delivers the current normalized speed and acceleration input to the engine effects controller
signal tune_engine_cone_minmax(min:float, max:float) ## Adjusts the engine cone min/max based on current state
signal ship_friction_cone_control ## Adjusts ship friction based on current state

# UI signals
signal update_speed_ui(current_speed:float, state_max_speed:float, accel_input:float, slide_boost_power:float)
signal update_stats_ui(current_health:int, current_shield:int, current_fuel:float)
signal health_changed(new_health:int)
signal shield_changed(new_shield:int)
signal fuel_changed(new_fuel:float)

# Sights UI signals
signal ping_sights(near:MeshInstance3D, far:MeshInstance3D)
signal update_sight_ui()
signal sight_lock_change(locked_on:bool)
signal lock_on_break()
signal check_line_of_sight() ## double check line of sight with a simple ray from player to target

# Camera signals
signal camera_Z_offset(player:Basis, orb_forward:Vector3) ## offsets the camera Z based on the difference in angle between the proxy_orbs forward velocity direction, and the players forward facing direction
signal reset_Z_offset
signal set_starting_z
signal camera_FOV_control(fov:float, duration:float)
signal gain_fuel(value:float)