class_name ShipResource extends Resource

@export_category("Hover Stats")
# Can't fly below this speed
@export var hovering_min_speed:float = 5.0
# Maximum airspeed
@export var hovering_max_speed:float = 50.0
# Turn rate
@export var hovering_turn_speed:float = 0.9
# Climb/dive rate
@export var hovering_pitch_speed:float = 0.75
# Wings "autolevel" speed
@export var hovering_level_speed:float = 3.0
# Throttle change speed
@export var hovering_throttle_delta:float = 50.0
# Acceleration/deceleration
@export var hovering_acceleration:float = 18.0
#roll strength
@export var hovering_rollMultiplier:float = 0.2
@export var fallingPitchMax:float = -0.5
@export var fallingPitchSpeedMax:float = 0.75
@export var fallingPitchBuildup:float = 0.2
@export var fallingPitchBase:float = 0.1
@export var slerp_speed:float = 10.0
@export var drift_turn_speed:float = 1.0
@export var drift_proxy_turn_speed:float = 0.25

@export_category("Flying Stats")
# Can't fly below this speed
@export var flying_min_speed:float = 5.0
# Maximum airspeed
@export var flying_max_speed:float = 50
# Turn rate
@export var flying_turn_speed:float = 0.9
# Climb/dive rate
@export var flying_pitch_speed:float = 0.75
# Wings "autolevel" speed
@export var flying_level_speed:float = 3.0
# Throttle change speed
@export var flying_throttle_delta:float = 50.0
# Acceleration/deceleration
@export var flying_acceleration:float = 18.0
#roll strength
@export var flying_rollMultiplier:float = 0.8

@export var rollCorrectionRate:float = 0.5