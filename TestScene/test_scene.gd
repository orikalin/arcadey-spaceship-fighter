extends Node3D
@export var player_container:PackedScene
@onready var spawn_point := %SpawnPoint
@onready var active_players := %ActivePlayers
@onready var base_camera := %BaseFollowCam
@onready var free_cam := %FreeCam
@onready var main_camera = %MainCamera
@onready var NetworkPopup := %NetworkPopup

func _physics_process(delta: float) -> void:	
	if Input.is_action_just_pressed("ui_cancel"):
		NetworkPopup.visible = not NetworkPopup.is_visible()
		if NetworkPopup.is_visible():
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED

func _ready():
	spawn_player()

# spawn the player
# connect the phantom cameras
# listen for new players

func spawn_player():
	var player = player_container.instantiate()
	player.spawn_transform = spawn_point.transform
	active_players.add_child(player)
	if not player.is_node_ready():
		await player.ready	
	base_camera.set_follow_target(player.get_mock_camera())
	assert(base_camera.follow_target != null, "base camera follow target is null") 
	var look_targets:Array[Node3D] = [
		player.get_player(),
		player.get_lookat_target()
	]
	base_camera.look_at_targets = look_targets
	base_camera.up_target = player.get_player()
	free_cam.follow_target = player.get_mock_camera()
	free_cam.look_at_target = player.get_player()
	free_cam.up_target = player.get_player()
