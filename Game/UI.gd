class_name UI
extends CanvasLayer

@export var players: Dictionary # id: player_ui
@export var stone_count: int 	# remaining stones
		
signal dragged
signal dropped

var player_ui: Dictionary		# all UI nodes accesible by player ID
var main_player: Control = null
@onready var pool: Control = $Pool

func _process(_delta):

	$Pool/Remaining.text = str(stone_count)
	
	if main_player:
		var x =  main_player.position.x + main_player.size.x + 40
		var y = main_player.position.y + main_player.size.y/2
		$Done.position = Vector2(x,y)
		$Done.size = Vector2(main_player.size.y/2, main_player.size.y/2)
		
		# position the pool area correctly
		x = main_player.position.x - 40 - 150
		y = main_player.position.y
		$Pool.position = Vector2(x,y)
		$Pool.size = Vector2(150, main_player.size.y)
	else:
		$Pool.visible = false
		$Done.visible = false

# called on done button pressed
func _on_done_pressed():
	%Server.request_end_turn.rpc_id(1)

func _create_player_node(id: int, player_name: String) -> Control:
	
	var player_scene = load("res://UI/Player_UI.tscn")
	var ui = player_scene.instantiate()
	ui.name = str(id)
	ui.set_multiplayer_authority(id)
	players[id] = ui
	ui.player_name = player_name
	
	return ui

func add_player(id: int, player_name: String):
	
	var ui = _create_player_node(id, player_name)
	if id == multiplayer.get_unique_id():
		$Player.add_child(ui)
		ui.custom_minimum_size = ui.custom_minimum_size*1.5
		main_player = ui
		main_player.dragged.connect(_on_dragged)
		main_player.dropped.connect(_on_dropped)
	else:
		$Player/RemotePlayer.add_child(ui)
	
func set_active_player(player: int):
	for pl in players:
		players[pl].set_active((pl == player))
	
	$Done.disabled = (player != multiplayer.get_unique_id())
	
func _on_dragged(stoneUI, rect):
	dragged.emit(stoneUI, rect)
	
func _on_dropped(stoneUI):
	dropped.emit(stoneUI)
