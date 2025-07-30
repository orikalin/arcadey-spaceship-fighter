extends Node

# Default game server port. Can be any number between 1024 and 49151.
# Not on the list of registered or common ports as of May 2024:
# https://en.wikipedia.org/wiki/List_of_TCP_and_UDP_port_numbers
const DEFAULT_PORT = 25384
const MAX_PEERS = 4

var peer : ENetMultiplayerPeer

# This enum lists all the possible states the character can be in.
enum States {IDLE, CONNECTING, CONNECTED, DISCONNECTING}

# This variable keeps track of the connection's current state.
var connection_state: States = States.IDLE

## Provides the friendly name of the local player
var local_player_name: String

signal connection_failed()
signal connection_succeeded()
signal disconnected()
signal connection_message(message:String)
signal player_list_changed()

var players := Dictionary()

func _ready() -> void:
	multiplayer.connection_failed.connect(_connection_failure)	
	multiplayer.peer_connected.connect(_player_connected)
	multiplayer.peer_disconnected.connect(_player_disconnected)
	
	if OS.has_environment("USERNAME"):
		local_player_name = OS.get_environment("USERNAME")
	else:
		var desktop_path := OS.get_system_dir(OS.SYSTEM_DIR_DESKTOP).replace("\\", "/").split("/")
		local_player_name = desktop_path[desktop_path.size() - 2]

func host_server() -> void:
	if connection_state != States.IDLE:
		connection_message.emit("Unable to join, connection already active")
		return
	connection_state = States.CONNECTING
	connection_message.emit("Starting Server on port " + str(DEFAULT_PORT) + "...")
	
	peer = ENetMultiplayerPeer.new()
	peer.create_server(DEFAULT_PORT, MAX_PEERS)
	multiplayer.set_multiplayer_peer(peer)
	
	connection_state = States.CONNECTED
	connection_message.emit("Server Started...")
	connection_succeeded.emit()
	player_list_changed.emit()
	
	
func join_server(ip_address: String) -> void:
	if connection_state != States.IDLE:
		connection_message.emit("Unable to join, connection already active")
		return
	connection_state = States.CONNECTING
	connection_message.emit("Connecting to " + ip_address + ":" + str(DEFAULT_PORT))
	
	peer = ENetMultiplayerPeer.new()
	peer.create_client(ip_address, DEFAULT_PORT)
	multiplayer.set_multiplayer_peer(peer)
	
	await multiplayer.connected_to_server
	connection_state = States.CONNECTED
	connection_succeeded.emit()

	
func shutdown_connection() -> void:
	connection_state = States.DISCONNECTING
	# TODO: What else do I need to do to shut down the server?
	multiplayer.set_multiplayer_peer(null) # Remove peer
	peer = null
	connection_state = States.IDLE
	connection_message.emit("Multiplayer Deactivated")
	disconnected.emit()
	
	
func _connection_failure() -> void:
	multiplayer.set_multiplayer_peer(null)
	shutdown_connection()
	

func _player_connected(id: int) -> void:
	connection_message.emit("Player " + str(id) +  " connected")
	register_player.rpc_id(id, local_player_name)
	
	
## Registers a player to the server
@rpc("any_peer")
func register_player(new_player_name: String) -> void:
	var id : int = multiplayer.get_remote_sender_id()
	players[id] = new_player_name
	player_list_changed.emit()
	
	
func _player_disconnected(id:int) -> void:
	connection_message.emit(str("Player ", id,  " disconnected"))
	players.erase(id)
	player_list_changed.emit()
