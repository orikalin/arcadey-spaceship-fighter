extends MeshInstance3D

var Player:CharacterBody3D
var currentSpeed:float

var EngineLights
var Particles
var EngineCones
var OmniLights
var Trails

@onready var hoveringState = %Hovering
@onready var flyingState = %Flying
@onready var ship_statemachine = %ShipStateMachine

@export var ParticleSizeCurve:Curve
@export var EngineLightCurve:Curve
@export var EngineConeCurve:Curve
@export var EngineLightIntensity:float = 1.5
@export var EngineLightEnergy:float = 4.5
@export var EngineConeMin:float = 0.1
@export var EngineConeMax:float = 0.9
@export var trail_width_min:float = 0.1
@export var trail_width_max:float = 0.555
@export var engine_cone_lerp_speed:float = 5.0



func _ready():
	Player = get_parent()
	EngineLights = $EngineLights.get_children()
	OmniLights = $OmniLights.get_children()
	# Particles = $Particles.get_children()
	Trails = $Trails.get_children()
	EngineCones = $EngineCones.get_children()
	var engine_cone_mesh:CylinderMesh = load("res://Assets/Materials/EngineConeMesh.tres").duplicate()
	for particles:CPUParticles3D in EngineCones:
		particles.mesh = engine_cone_mesh
	
func _process(delta:float):
	# if we are not the multiplayer authority, set the values recieved from multiplayer sync
	if not is_multiplayer_authority():
		for _trails:Trail3D in Trails:
				_trails.width = owner.trail_width
		for particles:CPUParticles3D in EngineCones:
			particles.mesh.top_radius = owner.engine_cone_top_rad
			particles.mesh.height = owner.engine_cone_height
		for spot_lights:SpotLight3D in EngineLights:
			spot_lights.spot_attenuation = owner.light_attenuation
			spot_lights.light_energy = owner.light_energy_spot
		for omni_lights:OmniLight3D in OmniLights:
			omni_lights.light_energy = owner.light_energy_omni
		return

	# if we are the multiplayer authority, run these processes	
	# Rewrite this logic to accept a normalized_forward_speed, and cut down calculations done per process
	# a
	if ship_statemachine != null:
		currentSpeed = ship_statemachine.currentState.forward_speed
		var EnginePower:float = Helpers.Map(currentSpeed, 0, ship_statemachine.ship_stats.hovering_max_speed, 0, 1)
		var is_drifting = ship_statemachine.currentState.name == "Drift"

		# Calculate results for various particles and materials
		var _EngineCurveSample:float = EngineLightCurve.sample(EnginePower)

		if EngineLights.size() > 0:
			var _light_attenuation:float = lerp(1.0, EngineLightIntensity, _EngineCurveSample)
			var _light_energy_spot:float = lerp(1.0, EngineLightEnergy, _EngineCurveSample)
			var _light_energy_omni:float = lerp(0.2, 2.0, _EngineCurveSample) 
			owner.light_attenuation = _light_attenuation
			owner.light_energy_spot = _light_energy_spot
			owner.light_energy_omni = _light_energy_omni
			for light:SpotLight3D in EngineLights:
				light.spot_attenuation = _light_attenuation
				light.light_energy = _light_energy_spot 
			for omni_light:OmniLight3D in OmniLights:
				omni_light.light_energy = _light_energy_omni
		if Trails.size() > 0:
			var _ParticleCurveSample:float = ParticleSizeCurve.sample(EnginePower)
			var trail_width = lerp(trail_width_min, trail_width_max, _ParticleCurveSample)
			for _trails:Trail3D in Trails:
				_trails.width = trail_width
				if is_drifting:
					_trails.width = trail_width * 0.8
					_trails.velocity_strength = _ParticleCurveSample
					owner.trail_width = trail_width * 0.8
				else:
					_trails.width = trail_width
					_trails.velocity_strength = 0.0
					owner.trail_width = trail_width
		if EngineCones.size() > 0:
			var _ParticleCurveSample:float
			if is_drifting:
				_ParticleCurveSample = EngineConeCurve.sample(ship_statemachine.ship_stats.drift_engine_power)
			else:
				_ParticleCurveSample = EngineConeCurve.sample(EnginePower)
			var _top_radius = lerp(EngineConeMin, EngineConeMax, _ParticleCurveSample)
			var _height = lerp(0.2, 0.6, _ParticleCurveSample)
			var _damping_min = lerp(1, 0, _ParticleCurveSample)
			var _damping_max = lerp(1, 0, _ParticleCurveSample)
			var _initial_velocity_min = lerp(0.1, 0.8, _ParticleCurveSample)
			var _initial_velocity_max = lerp(0.1, 0.8, _ParticleCurveSample)
			owner.engine_cone_top_rad = _top_radius
			owner.engine_cone_height = _height

			# Only need to set the mesh once, as the same instance should be used for both cones
			# EngineCones[0].mesh.top_radius = lerp(EngineCones[0].mesh.top_radius, _top_radius, delta*engine_cone_lerp_speed)
			# EngineCones[0].mesh.height = _height
			# EngineCones[0].damping_min = _damping_min
			# EngineCones[0].damping_max = _damping_max
			# EngineCones[0].initial_velocity_min = _initial_velocity_min
			# EngineCones[0].initial_velocity_max = _initial_velocity_max
			
			for particles:CPUParticles3D in EngineCones:
				particles.mesh.top_radius = lerp(particles.mesh.top_radius, _top_radius, delta*engine_cone_lerp_speed)
				particles.mesh.height = _height
				particles.damping_min = _damping_min
				particles.damping_max = _damping_max
				particles.initial_velocity_min = _initial_velocity_min
				particles.initial_velocity_max = _initial_velocity_max
		
		


	
	
