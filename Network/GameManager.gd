extends Node


var connected_players = {}


enum PlayerInfo {
	Name,
	Ready
}

signal player_changed(id)
signal player_added(id)
signal player_removed(id)
signal game_start(players)

func _ready():
	set_multiplayer_authority(1)
	
func disconnected():
	connected_players.clear()

func is_connected_to_server():
	return len(connected_players) != 0

func get_player_info():
	return connected_players[multiplayer.get_unique_id()]

func get_player_name(id):
	if not id in connected_players:
		return ""
		
	return connected_players[id][PlayerInfo.Name]

func add_player(id):
	if id == 1:
		return
		
	connected_players[id] = {PlayerInfo.Name: "Unknown", 
							 PlayerInfo.Ready: false}
	player_added.emit(id)

func remove_player(id):
	
	if id == 1:
		return
		
	connected_players.erase(id)
	player_removed.emit(id)

func update_player(id, info):

	if id == 1:
		return

	if not id in connected_players:
		add_player(id)	
		
	connected_players[id] = info
	player_changed.emit(id)
	
	# update the remote peers if this is a local change
	if id == multiplayer.get_unique_id():
		update_remote_player_info.rpc(info)
		
	# check if all players are ready (and there are more than 1)
	if is_multiplayer_authority():
		if len(connected_players) > 1:
			
			for player in connected_players:
				if not connected_players[player][PlayerInfo.Ready]:
					return
			
			start_game.rpc(connected_players.keys())
				
@rpc("any_peer", "call_remote", "reliable")
func update_remote_player_info(info):
	var id = multiplayer.get_remote_sender_id()
	GameManager.update_player(id, info)

@rpc("authority", "call_local", "reliable")
func start_game(players):
	game_start.emit(players)

func print_players():
	if multiplayer.is_server():
		return

	print("Players of ", multiplayer.get_unique_id())
	for id in connected_players:
		print("\tPlayer :", id)
		print("\t\tName:  ", connected_players[id][PlayerInfo.Name])
		print("\t\tReady: ", connected_players[id][PlayerInfo.Ready])
