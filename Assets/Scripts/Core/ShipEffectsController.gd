extends MeshInstance3D

var Player:CharacterBody3D
var currentSpeed:float
var engine_power:float
var accel_input:float
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
@export var TrailCurve:Curve
@export var EngineLightIntensity:float = 1.5
@export var EngineLightEnergy:float = 4.5
@export var EngineConeMin:float = 0.1
@export var EngineConeMax:float = 0.9
@export var trail_width_min:float = 0.1
@export var trail_width_max:float = 0.555
@export var engine_cone_lerp_speed:float = 5.0
@export var base_cone_drain:float = -0.2
@export var cone_flare_speed:float = 1
@export var trail_speed_velocity:float = 1.0
var target_cone_power:float = 0.2
var cone_flare_power:float

## ==================================================================================================
##	Rewrite this script to listen for event calls from SignalHub, and rewrite input code in states to 
##	emit those events, passing relevant data
## ==================================================================================================


func _ready():
	SignalHub.tune_engine_effects.connect(tune_engine_effects)
	SignalHub.tune_engine_cone_minmax.connect(tune_engine_cone_minmax)
	Player = get_parent()
	EngineLights = $EngineLights.get_children()
	OmniLights = $OmniLights.get_children()
	# Particles = $Particles.get_children()
	Trails = $Trails.get_children()
	EngineCones = $EngineCones.get_children()
	var engine_cone_mesh:CylinderMesh = load("res://Assets/Materials/EngineConeMesh.tres").duplicate()
	for particles:CPUParticles3D in EngineCones:
		particles.mesh = engine_cone_mesh


func tune_engine_lights():
	pass


func tune_engine_effects(_normalized_forward_speed:float, _accel_input:float, _cone_flare_power:float = 1.0):
	engine_power = _normalized_forward_speed
	accel_input = _accel_input
	cone_flare_power = _cone_flare_power


func tune_engine_cone_minmax(engine_cone_min:float, engine_cone_max:float):
	EngineConeMin = engine_cone_min
	EngineConeMax = engine_cone_max


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

	if ship_statemachine != null:
		currentSpeed = ship_statemachine.currentState.forward_speed
		#var EnginePower:float = Helpers.Map(currentSpeed, 0, ship_statemachine.ship_stats.hovering_max_speed, 0, 1)
		var EnginePower:float = Helpers.Map(currentSpeed, 0, ship_statemachine.currentState.state_max_speed, 0, 1)
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
			var _particle_curve_sample:float = ParticleSizeCurve.sample(engine_power)
			var _trail_curve_sample:float = TrailCurve.sample(engine_power)
			var trail_width = lerp(trail_width_min, trail_width_max, _particle_curve_sample)
			for _trails:Trail3D in Trails:
				_trails.width = trail_width
				if is_drifting:
					_trails.width = trail_width * 0.8
					_trails.velocity_strength = _trail_curve_sample
					owner.trail_width = trail_width * 0.8
				else:
					_trails.width = trail_width
					_trails.velocity_strength = _trail_curve_sample * trail_speed_velocity
					owner.trail_width = trail_width


		if EngineCones.size() > 0:
			# new throttle cone logic:
			# recieve throttle input, and curve sample += base_drain + throttle_input, result clamped between a min and max
			# min and max need to also be adjustable... separate function that can be called on state enter
			# lerp from current value to target value at a rate of lerp speed * delta
			target_cone_power = lerp(target_cone_power, accel_input, delta * cone_flare_speed * cone_flare_power)
			var _ConeCurveSmaple:float
			if is_drifting:
				_ConeCurveSmaple = EngineConeCurve.sample(ship_statemachine.ship_stats.drift_engine_power)
			else:
				_ConeCurveSmaple = EngineConeCurve.sample(target_cone_power)
			var _top_radius = lerp(EngineConeMin, EngineConeMax, _ConeCurveSmaple)
			var _height = lerp(0.2, 0.6, _ConeCurveSmaple)
			var _damping_min = lerp(1, 0, _ConeCurveSmaple)
			var _damping_max = lerp(1, 0, _ConeCurveSmaple)
			var _initial_velocity_min = lerp(0.1, 0.8, _ConeCurveSmaple)
			var _initial_velocity_max = lerp(0.1, 0.8, _ConeCurveSmaple)
			owner.engine_cone_top_rad = _top_radius
			owner.engine_cone_height = _height
			for particles:CPUParticles3D in EngineCones:
				particles.mesh.top_radius = lerp(particles.mesh.top_radius, _top_radius, delta*engine_cone_lerp_speed)
				particles.mesh.height = _height
				particles.damping_min = _damping_min
				particles.damping_max = _damping_max
				particles.initial_velocity_min = _initial_velocity_min
				particles.initial_velocity_max = _initial_velocity_max
		
		


	
	
