class_name Server
extends Node

signal game_ended

# game data, that is synced with the server
var players: Array[int]		# all players in the game
var stones:  Array[Vector3i] # all available stones indexed

# round data, that is synced with the server
enum Round_Type{started, playing, returning}
@export var current_player: int		# currently playing player
@export var round_type: Round_Type  # which type of round the player is playing

@onready var board: Board = %Board
@onready var ui: UI = %UI

# Called when the node enters the scene tree for the first time.
func _ready():
	set_multiplayer_authority(1)
	
	# setup all stones in the game
	for i in range(6):
		for j in range(6):
			for k in range(3):
				stones.append(Vector3i(i,j,k))

# draws a number of random stones, if available
func _draw_stones(num: int):
	var player_stones = []
	for i in range(min(len(stones), num)):
		var idx = randi() % len(stones)
		player_stones.append(stones[idx])
		stones.remove_at(idx)
			
	return player_stones

# Called locally to start the game. Only the server executes and setups the 
# game state
func start_game():
	
	if not is_multiplayer_authority():
		return 
		
	# give everyone stones!
	for player in players:
		var player_stones = _draw_stones(6)
		add_player_stones.rpc(player, player_stones)

	# set the starting player! 
	# TODO: Figure out who is the player with most
	#	    possible points and let him start
	set_current_player.rpc(players[0])



# called by clients to run on the server (use rpc_id(1) for those requests!)
# ******************************************************************************

# The current player can request to set the stone on the field
@rpc("any_peer", "call_remote", "reliable")
func request_set_stone(stone: Vector3i, cell: Vector2i):
	
	if not is_multiplayer_authority():
		return
		
	if multiplayer.get_remote_sender_id () != current_player:
		return
		
	if round_type != Round_Type.started and \
	   round_type != Round_Type.playing:
		return
	
	if not board.can_drop_in_cell(stone, cell):
		return
	
	set_stone.rpc(stone, cell)

# The current player can request to return a stone
@rpc("any_peer", "call_remote", "reliable")
func request_return_stone(stone: Vector3i):
	
	if not is_multiplayer_authority():
		return
		
	if multiplayer.get_remote_sender_id() != current_player:
		return
	
	if round_type != Round_Type.started and \
	   round_type != Round_Type.returning:
		return
	
	return_player_stone.rpc(current_player, stone)

# The current player can request to end his turn
@rpc("any_peer", "call_remote", "reliable")
func request_end_turn():
	
	if not is_multiplayer_authority():
		return

	if multiplayer.get_remote_sender_id() != current_player:
		return
	
	var ending_player = current_player
	
	# calcualte  and set the points
	var points = ui.players[current_player].points
	points += board.calculate_round_points()
	set_player_points.rpc(current_player, points)
	
	# check if the game ended
	var remaining_stones = ui.players[current_player].get_stone_count()
	var draw_stones = _draw_stones(6-remaining_stones)
	if remaining_stones == 0 and len(draw_stones) == 0:
		# end the game!
		set_player_points.rpc(current_player, points+6)
		end_game.rpc()
	
	# set the next player
	var idx = players.find(current_player)
	if idx >= (len(players)-1):
		idx = 0
	else:
		idx += 1
	set_current_player.rpc(players[idx])
	
	# get the finished player his new stones,. Do it after player change so that
	# he cannot use the new stones if the network is slow
	add_player_stones.rpc(ending_player, draw_stones)


# called by the server, executed by the client
# ******************************************************************************

# the current player is updated
@rpc("authority", "call_local", "reliable")
func set_current_player(player):
	
	current_player = player
	round_type = Round_Type.started
	board.new_player_turn(player)
	ui.set_active_player(player)

# a player receives new stones
@rpc("authority", "call_local", "reliable")
func add_player_stones(id, new_stones):
	for stone in new_stones:
		ui.players[id].add_stone(stone)
		var idx = stones.find(stone)
		if idx >= 0:
			stones.remove_at(idx)
			
	ui.stone_count = len(stones)

# a player returned a stone
@rpc("authority", "call_local", "reliable")
func return_player_stone(id, stone):
	stones.append(stone)
	round_type = Round_Type.returning

	ui.players[id].remove_stone(stone)
	ui.stone_count = len(stones)


# player points are updated
@rpc("authority", "call_local", "reliable")
func set_player_points(id, points):
	ui.players[id].points = points 

# a stone has been set on the field
@rpc("authority", "call_local", "reliable")
func set_stone(stone: Vector3i, position: Vector2i):
	round_type = Round_Type.playing
	board.set_stone(stone, position)
	ui.players[current_player].remove_stone(stone)
	
# the game ends
@rpc("authority", "call_local", "reliable")
func end_game():	
	# process the game end
	game_ended.emit()
