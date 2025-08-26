class_name ShipResource extends Resource

@export_category("Hovering Stats")
@export var rolling_max_speed:float = 100 ## Max speed
@export var rolling_turn_force:float = 8 ## Turn speed
@export var accel_force:float = 150 ## acceleration
@export var turn_stop_limit:float = 0 ## disallow turning if speed is below this value
@export var ground_alignment_speed:float = 12.0 ## speed at which
@export var player_alignment_speed:float = 12.0
@export var mesh_level_speed:float = 3.0
@export var mesh_roll_multiplier:float = 3.0
@export var gravity_airborne:float = 4.0
@export var gravity_grounded:float = 0.8
@export var ground_stick_force:float = 150 ## the local downward force applied to the player to keep grounded against gravity
@export var max_normal_alignment:float = 180.0
@export var falling_level_speed:float = 2
@export var ungrounded_grace:float = 0.1
@export var level_duration:float = 1.0
@export var stick_curve:Curve ## used to define a relationship between normalized forward speed and stick force
@export var easeInOut:Curve
@export var linear_damp:float = 0.24

@export_category("Boosting Stats")
@export var boost_max_speed:float = 160
@export var boost_accel_force:float = 300
@export var boost_min_duration:float = 1.0
@export var boost_turn_force:float = 7.0
@export var boost_ground_stick_force:float = 350
@export var boost_ground_alignment_speed:float = 12.0
@export var boost_player_alignment_speed:float = 2.0
@export var cone_flare_mult:float = 2.0
@export var charge_boost_accel_force:float = 600

@export_category("Drifting Stats")
@export var drift_turn_force:float = 12.0
@export var drift_ground_stick_force:float = 350
@export var drift_player_alignment_speed:float = 0.1
@export var drift_mesh_roll_multiplier:float = 0.8
@export var drift_linear_damp:float = 0.05
@export var drift_ungrounded_grace:float = 0.5
@export var drift_gravity:float = 0.0
@export var drift_speed_decay_duration:float = 6.0

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
@export var boost_cam_Y_offset:float = -0.8
@export var camera_FOV_offset:float = 0.2

@export var max_speed_decay_duration:float = 3.0
@export var max_speed_decay_multiplier:float = 1.0
var state_max_speed:float = 0.0



# old
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
@export var drift_turn_speed:float = 1.0
@export var drift_proxy_turn_speed:float = 0.25
@export var drift_engine_power:float = 0.25