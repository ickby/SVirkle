extends Node


# This is our main function, processes when the game starts
func _ready():
	# init random number generator	
	randomize()

	# general setup
	multiplayer.peer_connected.connect(peer_connected)
	multiplayer.peer_disconnected.connect(peer_disconnected)
	multiplayer.connected_to_server.connect(server_connected)
	multiplayer.server_disconnected.connect(server_disconnected)
	
	GameManager.game_start.connect(start_game)
	
	# check if we are server
	if DisplayServer.get_name() == "headless" or \
	   "--server" in OS.get_cmdline_user_args():

		start_server()
	
	# check if we run in the editor, and hence let the user decide what we are
	elif not OS.has_feature("editor"):
		start_client()


func start_server():
	print("start server")
	var peer = WebSocketMultiplayerPeer.new()
	var error = peer.create_server(8000)
	if error:
		print("Server setup failed: ", error)
		return
		
	multiplayer.multiplayer_peer = peer
	goto_lobby("Control")
	
func start_client():
	print("start client")
	var peer = WebSocketMultiplayerPeer.new()
	var error = peer.create_client("ws://207.154.217.133:8000")
	if error:
		print("Client setup failed")
		return
	
	multiplayer.multiplayer_peer = peer
	goto_lobby("Control")
	
func goto_lobby(remove: String):
	var scene = load("res://Network/lobby.tscn")
	var instance = scene.instantiate()
	instance.name = "lobby"
	get_node(remove).queue_free()
	add_child(instance)

func server_connected():
	GameManager.add_player(multiplayer.get_unique_id())

func server_disconnected():
	GameManager.disconnected()

func peer_connected(id):
	GameManager.add_player(id)	
	# send the new peer our information
	if not multiplayer.is_server():
		var info = GameManager.get_player_info()
		GameManager.update_remote_player_info.rpc_id(id, info)

func peer_disconnected(id):
	GameManager.remove_player(id)
	
func start_game(players):
	
	# set ourself to unready after starting the game 
	if not multiplayer.is_server():
		var info = GameManager.get_player_info()
		info[GameManager.PlayerInfo.Ready] = false
		GameManager.update_player(multiplayer.get_unique_id(), info)
		
	# remove the lobby
	get_node("lobby").queue_free()
	
	# add the game
	var game = load("res://Game/Game.tscn").instantiate()
	game.name = "Game"
	add_child(game)
	
	for player in players:
		game.add_player(GameManager.get_player_name(player), player)
	
	# connect the finish game callback
	game.finished.connect(_on_game_finished)
	
	game.start_game()

func _on_game_finished():
	goto_lobby("Game")
	
func _on_client_button_pressed():
	start_client()

func _on_server_button_pressed():
	start_server()

