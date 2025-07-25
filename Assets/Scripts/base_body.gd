extends MeshInstance3D

var PlayerControllerNode:CharacterBody3D
var target_speed:float
var EngineLights
@export var EngineLightCurve:Curve
@export var EngineLightIntensity:float = 2.5
@export var EngineLightEnergy:float = 3.5

func _ready():
	PlayerControllerNode = get_parent()
	EngineLights = $EngineLights.get_children()
	print_debug(EngineLights.size())
	
func _process(_delta:float):
	if PlayerControllerNode != null:
		target_speed = PlayerControllerNode.target_speed
		if EngineLights.size() > 0:
			var EnginePower = _Map(target_speed, 0, PlayerControllerNode.max_flight_speed, 0, 1)
			var _EngineCurveSample:float = EngineLightCurve.sample(EnginePower)
			for light:SpotLight3D in EngineLights:
				light.spot_attenuation = lerp(0.5, EngineLightIntensity, _EngineCurveSample)
				light.light_energy = lerp(1.0, EngineLightEnergy, _EngineCurveSample) 
				
func _physics_process(delta: float) -> void:pass
	
			
func _Map(val:float, min1:float, max1:float, min2:float, max2:float) -> float:
	return  min2 + (max2 - min2) * ((val - min1) / (max1 - min1))

	
	
