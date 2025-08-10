class_name ShipResource extends Resource

@export_category("Hover Stats : Old hover type")
@export var hovering_min_speed:float = 5.0
@export var hovering_max_speed:float = 50.0
@export var fallingPitchMax:float = -0.5
@export var fallingPitchSpeedMax:float = 0.75
@export var fallingPitchBuildup:float = 0.2
@export var fallingPitchBase:float = 0.1
@export var slerp_speed:float = 10.0
@export var hovering_turn_speed:float = 0.9
@export var hovering_pitch_speed:float = 0.75
@export var hovering_throttle_delta:float = 50.0
@export var hovering_level_speed:float = 3.0
@export var hovering_acceleration:float = 18.0
@export var hovering_roll_multiplier:float = 0.2

@export_category("Rolling Stats")
@export var accel_force:float = 180.0
@export var rolling_max_speed:float = 75.0
@export var rolling_turn_force:float = 9.0 
@export var turn_stop_limit:float = 180.0
@export var ground_alignment_speed:float = 5.0
@export var player_alignment_speed:float = 12.0
@export var mesh_level_speed:float = 3.0
@export var mesh_roll_multiplier:float = 0.2
@export var gravity_airborne:float = 4.0
@export var gravity_grounded:float = 0.2
@export var ground_stick_force:float = 150 ## the local downward force applied to the player to keep grounded against gravity
@export var max_normal_alignment:float = 180.0
@export var falling_level_speed:float = 6.0
@export var ungrounded_grace:float = 2.0
@export var level_duration:float = 1.0
@export var stick_curve:Curve ## used to define a relationship between normalized forward speed and stick force
@export var easeInOut:Curve

@export_category("Drifting Stats")
@export var drift_turn_speed:float = 1.0
@export var drift_proxy_turn_speed:float = 0.25
@export var drift_engine_power:float = 0.25

@export_category("Flying Stats")
@export var flying_min_speed:float = 5.0
@export var flying_max_speed:float = 50
@export var flying_turn_speed:float = 0.9
@export var flying_pitch_speed:float = 0.75
@export var flying_level_speed:float = 3.0
@export var flying_throttle_delta:float = 50.0
@export var flying_acceleration:float = 18.0
@export var flying_rollMultiplier:float = 0.8
@export var rollCorrectionRate:float = 0.5

@export_category("Camera Control Variables")
@export var camera_Y_offset:float = 1.8
@export var camera_FOV_offset:float = 0.2