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
	# Change the function that gets called on every system when spawning
	# a player
	PlayerSpawner.spawn_function = spawn_pawn_node
	
	# When we first load this scene, we aren't networked, so we spawn 
	# a local player
	spawn_local_player()
	
	# Whenever we start a network connection, we want to despawn that local
	# player, since we're going to be dealing with remote players.
	# In the future, we may want to record its position, velocity, etc.
	# So that we can copy that onto our new pawn.
	ConnectionSystem.connection_succeeded.connect(despawn_local_player)
	
	# If we're running this on the server, we want to listen for changes
	# to the player roster, and spawn players as needed.
	if multiplayer.is_server():
		ConnectionSystem.player_list_changed.connect(on_player_list_changed)

## Called by the server to spawn in a player.
func request_player_spawn(player_id: int) -> void:
	PlayerSpawner.spawn(player_id)

## Called on all systems when a player pawn is requested to be spawned in
## This is called on both the server and on all clients, once for each
## pawn that gets spawned in
func spawn_pawn_node(pawn_id: int) -> Node:
	# Just in case, we make sure the local player pawn is gone.
	despawn_local_player()
	
	# Create the node for the incoming pawn.
	var pawn = player_container.instantiate()
	pawn.spawn_transform = spawn_point.transform
	pawn.name = "Player" + str(pawn_id)
	
	# Make sure that this pawn gets the appropriate authority settings
	pawn.set_multiplayer_authority(pawn_id, true)
	
	# if the pawn we're spawning in here is the one this system owns,
	# we want to attach our camera to it.
	if pawn_id == multiplayer.get_unique_id():
		attach_camera_to_player(pawn)
		
	return pawn
	
# Only the server should be listening for changes to the player list
func on_player_list_changed():	
	
	# When we first start, we remove all active players.
	# This is disruptive and highly inefficient, but it simplifies
	# things later. We could do better than this by keeping a player
	# around if they're still in the list, and just making a list of
	# new players we need to spawn in.
	for connected_player in active_players.get_children():
		active_players.remove_child(connected_player)
		connected_player.queue_free()
		
	# The player list only contains remote players. 
	# We need to spawn ourselves in
	# Since we're the server, we always spawn with a network id
	# of 1
	request_player_spawn(1)
	
	# Now the server creates pawns for every remote player that is connected
	var players:Array = ConnectionSystem.players.keys()
	for player_id in players:
		request_player_spawn(player_id)

## Used to connect a camera to a player
func attach_camera_to_player(player:PlayerContainer) -> void:
	if not player.is_node_ready():
		# Wait... Does this actually work?!
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

## Spawns a local player pawn that is not in any way networked
func spawn_local_player():
	var player:PlayerContainer = player_container.instantiate()
	player.spawn_transform = spawn_point.transform
	local_player.add_child(player, true)
	attach_camera_to_player(player)
	

## Removes the local, un-networked, player pawn
func despawn_local_player():
	print_debug("Despawning local player pawn")
	# Remove the previous local player
	if local_player.get_child_count() > 0:
		var prev_local = local_player.get_child(0)
		local_player.remove_child(prev_local)
		prev_local.queue_free()

	
