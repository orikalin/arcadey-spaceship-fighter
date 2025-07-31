extends MeshInstance3D

var Player:CharacterBody3D
var currentSpeed:float
var EngineLights
var Particles
var EngineCones
var OmniLights

@onready var hoveringState = %Hovering
@onready var flyingState = %Flying
@onready var shipStateMachine = %ShipStateMachine

@export var ParticleSizeCurve:Curve
@export var EngineLightCurve:Curve
@export var EngineConeCurve:Curve
@export var EngineLightIntensity:float = 1.5
@export var EngineLightEnergy:float = 4.5
@export var EngineConeMin:float = 0.1
@export var EngineConeMax:float = 0.9

func _ready():
	Player = get_parent()
	EngineLights = $EngineLights.get_children()
	OmniLights = $OmniLights.get_children()
	Particles = $Particles.get_children()
	EngineCones = $EngineCones.get_children()
	var engine_cone_mesh:CylinderMesh = load("res://Assets/Materials/EngineConeMesh.tres").duplicate()
	for particles:CPUParticles3D in EngineCones:
		particles.mesh = engine_cone_mesh
	
func _process(_delta:float):
	if not is_multiplayer_authority():
		for particles:CPUParticles3D in Particles:
			particles.scale_amount_min = owner.trails_scale_min
			particles.scale_amount_max = owner.trails_scale_max
		for particles:CPUParticles3D in EngineCones:
			particles.mesh.top_radius = owner.engine_cone_top_rad
			particles.mesh.height = owner.engine_cone_height
		for spot_lights:SpotLight3D in EngineLights:
			spot_lights.spot_attenuation = owner.light_attenuation
			spot_lights.light_energy = owner.light_energy_spot
		for omni_lights:OmniLight3D in OmniLights:
			omni_lights.light_energy = owner.light_energy_omni
		return
	if shipStateMachine != null:
		currentSpeed = shipStateMachine.currentState.forward_speed
		var EnginePower:float = Helpers.Map(currentSpeed, 0, shipStateMachine.ship_stats.hovering_max_speed, 0, 1)
		
		if EngineLights.size() > 0:
			var _EngineCurveSample:float = EngineLightCurve.sample(EnginePower)
			var _light_energy_spot:float = lerp(1.0, EngineLightEnergy, _EngineCurveSample)
			var _light_energy_omni:float = lerp(0.2, 2.0, _EngineCurveSample) 
			var _light_attenuation:float = lerp(1.0, EngineLightIntensity, _EngineCurveSample)
			owner.light_energy_spot = _light_energy_spot
			owner.light_energy_omni = _light_energy_omni
			owner.light_attenuation = _light_attenuation
			for light:SpotLight3D in EngineLights:
				light.spot_attenuation = _light_attenuation
				light.light_energy = _light_energy_spot 
			for omni_light:OmniLight3D in OmniLights:
				omni_light.light_energy = _light_energy_omni
		if Particles.size() > 0:
			var _ParticleCurveSample:float = ParticleSizeCurve.sample(EnginePower)
			var _scale_min = lerp(0, 1, _ParticleCurveSample)
			var _scale_max = lerp(0, 1, _ParticleCurveSample)
			owner.trails_scale_min = _scale_min
			owner.trails_scale_max = _scale_max
			for particles:CPUParticles3D in Particles:
				particles.scale_amount_min = _scale_min
				particles.scale_amount_max = _scale_max
		if EngineCones.size() > 0:
			var __ParticleCurveSample:float = EngineConeCurve.sample(EnginePower)
			var _top_radius = lerp(EngineConeMin, EngineConeMax, __ParticleCurveSample)
			var _height = lerp(0.2, 0.6, __ParticleCurveSample)
			var _damping_min = lerp(1, 0, __ParticleCurveSample)
			var _damping_max = lerp(1, 0, __ParticleCurveSample)
			var _initial_velocity_min = lerp(0.1, 0.8, __ParticleCurveSample)
			var _initial_velocity_max = lerp(0.1, 0.8, __ParticleCurveSample)
			owner.engine_cone_top_rad = _top_radius
			owner.engine_cone_height = _height
			for particles:CPUParticles3D in EngineCones:
				particles.mesh.top_radius = _top_radius
				particles.mesh.height = _height
				particles.damping_min = _damping_min
				particles.damping_max = _damping_max
				particles.initial_velocity_min = _initial_velocity_min
				particles.initial_velocity_max = _initial_velocity_max
		
		


	
	
