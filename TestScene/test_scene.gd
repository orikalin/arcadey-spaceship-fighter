extends Node3D
@export var player_container:PackedScene
@onready var spawn_point := %SpawnPoint
@onready var active_players := %ActivePlayers
@onready var local_player := %LocalPlayer
@onready var base_camera := %BaseFollowCam
@onready var free_cam := %FreeCam
@onready var main_camera = %MainCamera
@onready var NetworkPopup := %NetworkPopup

func _physics_process(delta: float) -> void:	
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Input.is_action_just_pressed("network"):
		NetworkPopup.visible = not NetworkPopup.is_visible()

func _ready():
	spawn_local_player()
	ConnectionSystem.player_list_changed.connect(on_player_list_changed)

# spawn the player
# connect the phantom cameras
# listen for new players

func on_player_list_changed():
	if not multiplayer.is_server():
		return
	
	for connected_player in active_players.get_children():
		active_players.remove_child(connected_player)
		connected_player.queue_free()

	var LCL_player:PlayerContainer = player_container.instantiate()
	LCL_player.spawn_transform = spawn_point.transform
	LCL_player.network_id = multiplayer.get_unique_id()
	active_players.add_child(LCL_player)

	# Remove the previous local player
	if local_player.get_child_count() > 0:
		var prev_local = local_player.get_child(0)
		local_player.remove_child(prev_local)
		prev_local.queue_free()

	attach_camera_to_player(LCL_player)
	var players:Array = ConnectionSystem.players.keys()
	for player_id in players:
		var player = player_container.instantiate()
		player.spawn_transform = spawn_point.transform
		player.network_id = player_id
		player.set_multiplayer_authority(player_id, true)
		active_players.add_child(player)
	possess_puppet.rpc()


func attach_camera_to_player(player:PlayerContainer) -> void:
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


func spawn_local_player():
	var player:PlayerContainer = player_container.instantiate()
	player.spawn_transform = spawn_point.transform
	local_player.add_child(player)
	attach_camera_to_player(player)


@rpc("reliable")
func possess_puppet():
	# Remove the previous local player
	if local_player.get_child_count() > 0:
		var prev_local = local_player.get_child(0)
		local_player.remove_child(prev_local)
		prev_local.queue_free()
	for _player in active_players.get_children():
		if _player.network_id == multiplayer.get_unique_id():
			attach_camera_to_player(_player)
	
