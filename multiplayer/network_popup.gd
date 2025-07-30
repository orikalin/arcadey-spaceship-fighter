extends Panel

@onready var StatusLight := %StatusLight
@onready var LogBox := %NetworkLog
@onready var IpAddress := %IpAddress
@onready var PlayerName := %PlayerName

func _ready() -> void:
	ConnectionSystem.connection_message.connect(_on_connection_message)
	ConnectionSystem.connection_succeeded.connect(_on_connection_succeeded)
	ConnectionSystem.connection_failed.connect(_on_connection_failed)
	ConnectionSystem.disconnected.connect(_on_disconnection)
	StatusLight.color = Color.BLUE
	
	PlayerName.placeholder_text = ConnectionSystem.local_player_name
	
	
func _on_connection_message(msg: String) -> void:
	LogBox.add_text(msg + "\n")
	
	
func _on_connection_succeeded() -> void:
	StatusLight.color = Color.GREEN
	
	
func _on_connection_failed() -> void:
	StatusLight.color = Color.RED
	
	
func _on_disconnection() -> void:
	StatusLight.color = Color.BLUE


func _on_host_game_pressed() -> void:
	if PlayerName.text.length() > 0:
		ConnectionSystem.local_player_name = PlayerName.text
	ConnectionSystem.host_server()


func _on_join_game_pressed() -> void:
	if PlayerName.text.length() > 0:
		ConnectionSystem.local_player_name = PlayerName.text
	var connection_ip := "127.0.0.1"
	if IpAddress.text.length() > 0:
		connection_ip = IpAddress.text
	ConnectionSystem.join_server(connection_ip)


func _on_visibility_changed() -> void:
	pass # Replace with function body.
