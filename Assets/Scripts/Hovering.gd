extends State


var min_speed = 5

var max_speed = 50

var turn_speed = 0.9

var pitch_speed = 0.75

var level_speed = 3.0

var throttle_delta = 50

var acceleration = 18.0

# Current speed
var forward_speed:float = 0.0
# Throttle input speed
var target_speed:float = 0.0
# Lets us disable certain things when grounded
var grounded = false

var turn_input:float = 0.0
var pitch_input:float = 0.0

func physicsUpdate(delta:float):
    if Input.is_action_pressed("swapMode"):
        finished.emit("Flying", {})
