extends Node

@export var fuel_regen_start_delay:float = 1.0
@export var fuel_regen_rate:float = 2.0

var fuel_regen_timer:float = 0.0

@onready var ship_statemachine:StateMachine = %ShipStateMachine

func _ready():
	SignalHub.gain_fuel.connect(gain_fuel)

func _process(delta):
	if ship_statemachine.currentState.name == "boost":
		fuel_regen_timer = 0.0
	elif fuel_regen_timer < fuel_regen_start_delay:
		fuel_regen_timer += delta
	else:
		gain_fuel(delta*fuel_regen_rate)



func gain_fuel(value:float) -> void:
	ship_statemachine.ship_stats.boost_fuel_current += value
