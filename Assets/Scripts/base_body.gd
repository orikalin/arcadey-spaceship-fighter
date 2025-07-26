extends MeshInstance3D

var PlayerControllerNode:CharacterBody3D
var target_speed:float
var EngineLights
var Particles
@onready var flyingState = $"../ShipStateMachine/Flying"
@export var ParticleSizeCurve:Curve
@export var EngineLightCurve:Curve
@export var EngineLightIntensity:float = 2.5
@export var EngineLightEnergy:float = 3.5

func _ready():
	PlayerControllerNode = get_parent()
	EngineLights = $EngineLights.get_children()
	Particles = $Particles.get_children()
	print_debug(EngineLights.size())
	
func _process(_delta:float):
	if flyingState != null:
		target_speed = flyingState.target_speed
		var EnginePower = Helpers.Map(target_speed, 0, flyingState.max_flight_speed, 0, 1)
		if EngineLights.size() > 0:
			var _EngineCurveSample:float = EngineLightCurve.sample(EnginePower)
			for light:SpotLight3D in EngineLights:
				light.spot_attenuation = lerp(0.5, EngineLightIntensity, _EngineCurveSample)
				light.light_energy = lerp(1.0, EngineLightEnergy, _EngineCurveSample) 
		if Particles.size() > 0:
			var _ParticleCurveSample:float = ParticleSizeCurve.sample(EnginePower)
			for particles:CPUParticles3D in Particles:
				#particles.scale_amount_min = lerp()
				particles.scale_amount_min = lerp(0, 1, _ParticleCurveSample)
				particles.scale_amount_max = lerp(0, 1, _ParticleCurveSample)


	
	
