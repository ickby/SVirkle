extends Control


# Called when the node enters the scene tree for the first time.
func _ready():
	
	# populate the players!
	for player in GameManager.connected_players:
		player_added(player)
	
	# listen for changes
	GameManager.player_added.connect(player_added)
	GameManager.player_removed.connect(player_removed)
	GameManager.player_changed.connect(player_changed)
	
	# no actions needed for server
	if multiplayer.is_server():
		$VBoxContainer/Label.visible = false
		$VBoxContainer/HBoxContainer/Name.visible = false
		$VBoxContainer/HBoxContainer/Ready.visible= false
	
	elif GameManager.is_connected_to_server():
		var info = GameManager.get_player_info()
		if info[GameManager.PlayerInfo.Name] != "Unknown":
			$VBoxContainer/HBoxContainer/Name.text = info[GameManager.PlayerInfo.Name]
		
		$VBoxContainer/HBoxContainer/Ready.button_pressed = info[GameManager.PlayerInfo.Ready]

func player_added(id):
	var player_scene = load("res://Network/LobbyPlayer.tscn")
	var player_container = get_node("VBoxContainer/Panel/ScrollContainer/Players")

	var node = player_scene.instantiate()	  
	player_container.add_child(node)
	node.name = "%s"%id # Node name is player ID for easy search
	
	# fill in the data
	player_changed(id)
	
func player_removed(id):
	get_node("VBoxContainer/Panel/ScrollContainer/Players/%s"%id).queue_free()
	
func player_changed(id):
	var info = GameManager.connected_players[id]
	var player_node = get_node("VBoxContainer/Panel/ScrollContainer/Players/%s"%id)
	
	if id == multiplayer.get_unique_id() and info[GameManager.PlayerInfo.Name] == "Unknown":
		player_node.set_player_name("You")
	else:
		player_node.set_player_name(info[GameManager.PlayerInfo.Name])
	
	if info[GameManager.PlayerInfo.Ready]:
		player_node.set_player_status("Ready")
	else:
		player_node.set_player_status("Not Ready")

func _on_name_text_submitted(new_text):
	var info = GameManager.get_player_info()
	info[GameManager.PlayerInfo.Name] = new_text
	GameManager.update_player(multiplayer.get_unique_id(), info)

func _on_ready_toggled(toggled_on):
	var info = GameManager.get_player_info()
	info[GameManager.PlayerInfo.Ready] = toggled_on
	GameManager.update_player(multiplayer.get_unique_id(), info)
