extends Panel

@onready var PlayerList := %Players

func _ready() -> void:
	ConnectionSystem.player_list_changed.connect(_on_player_list_changed)
	ConnectionSystem.connection_succeeded.connect(_on_connection_succeeded)
	ConnectionSystem.disconnected.connect(_on_disconnected)


func _on_connection_succeeded() -> void:
	show()
	
	
func _on_disconnected() -> void:
	hide()
	

func _on_player_list_changed() -> void:	
	var players = ConnectionSystem.players	
	players.sort()
	PlayerList.clear()
	PlayerList.add_item(ConnectionSystem.local_player_name + " (you)")
	for p: String in players.values():
		PlayerList.add_item(p)
