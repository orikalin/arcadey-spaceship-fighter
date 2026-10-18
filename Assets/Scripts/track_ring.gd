extends Node3D

@export var slerp_speed:float = 10.0

var collected:bool = false
var player
var reset_pos:Vector3
var reset_basis:Basis
var reset_xform:Transform3D

@onready var ring:MeshInstance3D = $track_ring
@onready var anim:AnimationPlayer = %AnimationPlayer
@onready var trigger_area:CollisionShape3D = %CollisionShape3D

func _ready():
	await get_tree().create_timer(5).timeout
	reset_basis = ring.basis
	reset_pos = global_position
	reset_xform = global_transform
	anim.play("IDLE")

func _physics_process(delta: float) -> void:
	if collected:
		global_position = player.global_position
		rotation = player.rotation

		


func _on_area_3d_body_entered(body:Node3D) -> void:
	if body.name == "Player":
		SignalHub.gain_fuel.emit(20.0)
		player = body
		trigger_area.disabled = true
		anim.play("COLLECT")
		collected = true
		await anim.animation_finished
		self.visible = false
		collected = false
		await get_tree().create_timer(3.0).timeout
		anim.play("IDLE")
		global_transform = reset_xform
		# ring.position = reset_pos
		ring.basis = reset_basis
		self.visible = true
		trigger_area.disabled = false

		
