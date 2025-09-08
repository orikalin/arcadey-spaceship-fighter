extends RichTextLabel

var health:int = 0
var shield:int = 0
var fuel:float = 0.0

func _ready() -> void:
	SignalHub.health_changed.connect(update_health)
	SignalHub.shield_changed.connect(update_shield)
	SignalHub.fuel_changed.connect(update_fuel)


func update_health(_health:int) -> void:
	health = _health
	update_stats_ui(health, shield, fuel)

func update_shield(_shield:int) -> void:
	shield = _shield
	update_stats_ui(health, shield, fuel)

func update_fuel(_fuel:float) -> void:
	fuel = _fuel
	update_stats_ui(health, shield, fuel)


func update_stats_ui(_health:int = 0, _shield:int = 0, _fuel:float = 0.0):
	var formated_fuel := "%.2f" % _fuel
	self.bbcode_text = str(_health) + "\n" + str(_shield) + "\n" +  str(formated_fuel)
