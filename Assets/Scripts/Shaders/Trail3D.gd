class_name Trail3D extends MeshInstance3D

var _points = [] #stores all 3D positions that will make up the trail
var _widths = [] #stores all calculated widths using the positions of the points
var _lifePoints = [] #stores all the trail points and lifespans

@export var _trailEnabled : bool = true

@export var _fromWidth : float = 0.5 ## Starting width of the trail
@export var _toWidth : float = 0.0 ## End width of the trail
@export_range(0.5, 1.5) var _scaleAcceleration : float = 1.0 ## Speed of the scaling

@export var _motionDelta : float = 0.1 ## Sets the smoothness of the trail, how long it will take for a new trail piece to be made
@export var _lifespan : float = 1.0 ## Sets the duration until this part of the trail is no longer used, and is thus removed

@export var _startColor : Color = Color(1.0,1.0,1.0,1.0) ## Starting color of the trail
@export var _endColor : Color = Color(1.0,1.0,1.0,0.0) ## Ending color of the trail

var _oldPos : Vector3 # previous position

func _ready():
	_oldPos = get_global_transform().origin
	mesh = ImmediateMesh.new()

func AppendPoint():
	_points.append(get_global_transform().origin)
	_widths.append([
		get_global_transform().basis.x * _fromWidth,
		get_global_transform().basis.x * _fromWidth - get_global_transform().basis.x * _toWidth])
	_lifePoints.append(0.0)

func RemovePoint(i):
	_points.remove_at(i)
	_widths.remove_at(i)
	_lifePoints.remove_at(i)

func _process(delta: float):
	if (_oldPos - get_global_transform().origin).length() > _motionDelta and _trailEnabled:
		AppendPoint()
		_oldPos = get_global_transform().origin

	var p = 0
	var max_points = _points.size()
	while p < max_points:
		_lifePoints[p] += delta
		if _lifePoints[p] > _lifespan:
			RemovePoint(p)
			p -= 1
			if (p < 0) : p = 0
		max_points = _points.size()
		p += 1

	mesh.clear_surfaces()

	if _points.size() < 2:
		return

	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in range(_points.size()):
		var t = float(i) / (_points.size() - 1.0)
		var currColor = _startColor.lerp(_endColor, 1 - t)
		mesh.surface_set_color(currColor)

		var currWidth = _widths[i][0] - pow(1 - t, _scaleAcceleration) * _widths[i][1]

		var t0 = i / _points.size()
		var t1 = t

		mesh.surface_set_uv(Vector2(t0, 0 ))
		mesh.surface_add_vertex(to_local(_points[i] + currWidth))
		mesh.surface_set_uv(Vector2(t1, 1))
		mesh.surface_add_vertex(to_local(_points[i] - currWidth))
	mesh.surface_end()
