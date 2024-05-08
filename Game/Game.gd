extends Node2D

signal finished		# emitted when the game finished and the player wants ot leave

@onready var board: Board = %Board
@onready var ui: UI = %UI
@onready var server: Server = %Server

var scaled: bool = false

# Called when the node enters the scene tree for the first time.
func _ready():

	# place the board central
	board.position -= Vector2(90,90)
	
	# connect signals 
	ui.dragged.connect(_on_stone_dragged)
	ui.dropped.connect(_on_stone_dropped)
	server.game_ended.connect(_on_game_end)
		
	# test code
	if false:
		add_player("Stefan", multiplayer.get_unique_id())
		add_player("Verena", 8598594)
		add_player("Ann-Katrin", 85948594)
		
		# for testing we call directly, no rpc...
		server.add_player_stones(multiplayer.get_unique_id(), [Vector3i(5,0,0), Vector3i(3,3,0)])
		server.add_player_stones(8598594, [Vector3i(1,3,0), Vector3i(4,2,0)])
		server.add_player_stones(85948594, [Vector3i(2,1,0), Vector3i(0,5,0)])
		
		server.set_current_player(multiplayer.get_unique_id())

func add_player(player_name, id):
	
	server.players.append(id)
	ui.add_player(id, player_name)

func start_game():
	server.start_game()

func _on_game_end():
	
	if multiplayer.is_server():
		# no endscreen for server, directly go back!
		finished.emit()
		return
	
	# no active players!
	# deactivate players!
	ui.set_active_player(1)
		
	# determine the winner
	var winner = ""
	var max_points = 0
	for player in ui.players:
		var player_points = ui.players[player].points
		if player_points > max_points:
			winner = ui.players[player].player_name
			max_points = ui.players[player].points
	
	# show the endscreen
	var end_scene = load("res://Game/Endscreen.tscn")
	var end_node = end_scene.instantiate()
	end_node.set_winner(winner)
	end_node.go_back.connect(_on_lobby_return)
	ui.add_child(end_node)

func _on_lobby_return():
	finished.emit()

func _on_stone_dragged(stone: StoneUI, rect: Rect2):
	
	# check if we are outside of the main player control, and the rescale the 
	# stone accordingly
	var new_rect = Rect2(rect.position+ui.main_player.position, rect.size)
	if not ui.main_player.get_rect().intersects(new_rect) and \
	   not ui.pool.get_rect().intersects(new_rect):
		
		# snap to board if possible. Stone is positioned relative to player 
		var pos = board.get_snap_position_in_screen_coords()
		if pos.x >= 0:
			stone.position = pos - (ui.main_player.position + ui.main_player.get_drag_position_offset())

		if not scaled: 
			scaled = true

			# calculate the correct size!
			var size = 180 * $Camera.zoom.x
			
			# animate the change
			var tween = create_tween()
			tween.tween_property(stone, "size", size, 0.1)
			
	elif scaled:
		scaled = false
		# animate the change
		var tween = create_tween()
		tween.tween_property(stone, "size", ui.main_player.get_stone_size(), 0.1)

func _on_stone_dropped(stone: StoneUI):

	scaled = false	
	
	# check if dropped on pool or on board
	if Rect2(Vector2(), ui.pool.size).has_point(ui.pool.get_local_mouse_position()):
		
		if server.round_type != server.Round_Type.playing:
			server.request_return_stone.rpc_id(1, stone.stone)
	else:
		if server.round_type != server.Round_Type.returning:
			# dropped over board
			var cell = board.get_drop_cell()
			if board.can_drop_in_cell(stone.stone, cell):
				stone.set_fixed()
				server.request_set_stone.rpc_id(1, stone.stone, cell)

