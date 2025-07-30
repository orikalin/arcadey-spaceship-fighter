extends Node3D

@export var player_container:PackedScene
@onready var spawn_point := %SpawnPoint
@onready var active_players := %ActivePlayers
@onready var local_player := %LocalPlayer
@onready var base_camera := %BaseFollowCam
@onready var free_cam := %FreeCam
@onready var main_camera = %MainCamera
@onready var NetworkPopup := %NetworkPopup
@onready var PlayerSpawner := %PlayerSpawner


func _physics_process(delta: float) -> void:	
	if Input.is_action_just_pressed("ui_cancel"):
		if Input.mouse_mode == Input.MOUSE_MODE_CAPTURED:
			Input.mouse_mode = Input.MOUSE_MODE_VISIBLE
		else:
			Input.mouse_mode = Input.MOUSE_MODE_CAPTURED
	if Input.is_action_just_pressed("network"):
		NetworkPopup.visible = not NetworkPopup.is_visible()


func _ready():
	PlayerSpawner.spawn_function = spawn_networked_player
	spawn_local_player()
	ConnectionSystem.connection_succeeded.connect(despawn_local_player)
	
	if multiplayer.is_server():
		ConnectionSystem.player_list_changed.connect(on_player_list_changed)

# spawn the player
# connect the phantom cameras
# listen for new players

func request_player_spawn(player_id: int) -> void:
	PlayerSpawner.spawn(player_id)

func spawn_networked_player(player_id: int) -> Node:
	print_debug("client spawn_networked_player")
	despawn_local_player()
	
	var player = player_container.instantiate()
	player.get_node("%MultiplayerData").spawn_transform = spawn_point.transform
	player.get_node("%MultiplayerData").network_id = player_id
	player.name = "Player" + str(player_id)
	player.set_multiplayer_authority(player_id, true)
	player.get_node("%MultiplayerData").set_multiplayer_authority(1)
	
	if player_id == multiplayer.get_unique_id():
		attach_camera_to_player(player)
		
	return player
	

func on_player_list_changed():	
	for connected_player in active_players.get_children():
		active_players.remove_child(connected_player)
		connected_player.queue_free()
		
	request_player_spawn(1)
	
	var players:Array = ConnectionSystem.players.keys()
	for player_id in players:
		request_player_spawn(player_id)


func attach_camera_to_player(player:PlayerContainer) -> void:
	if not player.is_node_ready():
		await player.ready	
	var packed_camera_manager:CameraManager = player.get_node("%CameraManager")
	packed_camera_manager.phantom_free_cam = %FreeCam
	packed_camera_manager.phantom_base_cam = %BaseFollowCam
	var look_targets:Array[Node3D] = [
		player.get_player(),
		player.get_lookat_target()
	]
	base_camera.set_follow_target(player.get_mock_camera())
	base_camera.look_at_targets = look_targets
	base_camera.up_target = player.get_player()
	free_cam.follow_target = player.get_mock_camera()
	free_cam.look_at_target = player.get_player()
	free_cam.up_target = player.get_player()


func spawn_local_player():
	var player:PlayerContainer = player_container.instantiate()
	player.get_node("%MultiplayerData").spawn_transform = spawn_point.transform
	local_player.add_child(player, true)
	attach_camera_to_player(player)
	
	
func despawn_local_player():
	print_debug("Despawning local player")
	# Remove the previous local player
	if local_player.get_child_count() > 0:
		var prev_local = local_player.get_child(0)
		local_player.remove_child(prev_local)
		prev_local.queue_free()

	
