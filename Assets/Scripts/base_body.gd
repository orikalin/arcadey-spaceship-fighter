extends MeshInstance3D

var Player:CharacterBody3D
var currentSpeed:float
var EngineLights
var Particles
var EngineCones
var OmniLights
@onready var hoveringState = $"../shipStateMachine/Hovering"
@onready var flyingState = $"../shipStateMachine/Flying"
@onready var shipStateMachine = $"../ShipStateMachine"
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
	
func _process(_delta:float):
	if not is_multiplayer_authority():
		for particles:CPUParticles3D in Particles:
			particles.scale_amount_min = owner.trails_scale_min
			particles.scale_amount_max = owner.trails_scale_max
		for particles:CPUParticles3D in EngineCones:
			particles.mesh.top_radius = owner.engine_cone_top_rad
			particles.mesh.height = owner.engine_cone_height
		return
	if shipStateMachine != null:
		currentSpeed = shipStateMachine.currentState.forward_speed
		var EnginePower:float = Helpers.Map(currentSpeed, 0, shipStateMachine.ship_stats.hovering_max_speed, 0, 1)
		
		if EngineLights.size() > 0:
			var _EngineCurveSample:float = EngineLightCurve.sample(EnginePower)
			for light:SpotLight3D in EngineLights:
				light.spot_attenuation = lerp(1.0, EngineLightIntensity, _EngineCurveSample)
				light.light_energy = lerp(1.0, EngineLightEnergy, _EngineCurveSample) 
			for omni_light:OmniLight3D in OmniLights:
				omni_light.light_energy = lerp(0.2, 2.0, _EngineCurveSample) 
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


		
			# var _coneMesh:CylinderMesh = EngineCones[0].mesh
			# _coneMesh.top_radius = lerp(0.4, 0.9, __ParticleCurveSample)
			# EngineCones[0].mesh = _coneMesh
			# for particles:CPUParticles3D in EngineCones:
		
		


	
	
