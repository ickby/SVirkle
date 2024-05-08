class_name Board
extends Node2D

var current_player: int
var round_cells: Array[Vector2i] # this are the cells we placed stones in
@onready var tilemap: TileMap = $TileMap

# Called when the node enters the scene tree for the first time.
func _ready():
	
	# test code
	if false:
		set_stone(Vector3i(2,3,0), Vector2i(0,0))
		set_stone(Vector3i(0,5,0), Vector2i(0,1))
		set_stone(Vector3i(4,4,0), Vector2i(1,0))

func _draw():
	# draws the grid
	var rect = tilemap.get_used_rect()
	if rect.size.x == 0:
		rect.size = Vector2i(1,1)
	
	var pos = rect.position - Vector2i(1,1)
	var size = rect.size + Vector2i(2,2)

	for i in range(1,size.x):
		draw_line(Vector2((pos.x+i)*180, pos.y*180), Vector2((pos.x+i)*180, (pos.y+size.y)*180),Color(0.5,0.5,0.5))
	for i in range(1,size.y):
		draw_line(Vector2((pos.x)*180, (pos.y+i)*180), Vector2((pos.x+size.x)*180, (pos.y+i)*180),Color(0.5,0.5,0.5))

func set_stone(stone: Vector3i, cell: Vector2i):
	round_cells.append(cell)
	tilemap.set_cell(0, cell, 0, Vector2i(stone.x, stone.y))
	queue_redraw()

func new_player_turn(player:int):
	round_cells.clear()
	current_player = player
	
func _get_surrounding_cells(cell: Vector2i, null_for_empty: bool):
	# get surounding used cells, in the order [Top, Left, Bottom, Rigth]
	# if null_for_empty = true, then a not existing neighbour is represented by 
	# a null in the array, if false, it is just ommited
	var used = tilemap.get_used_cells(0)
	var neighbours = [	Vector2i(cell.x-1, cell.y), 
						Vector2i(cell.x+1, cell.y),
						Vector2i(cell.x, cell.y-1),
						Vector2i(cell.x, cell.y+1) ];
	
	var result = []
	for nb in neighbours:
		if nb in used:
			result.append(nb)
		elif null_for_empty:
			result.append(null)
	
	return result

func _get_surrounding_stones(cell: Vector2i, null_for_empty: bool):
	# get surounding stones, in the order [Top, Left, Bottom, Rigth]
	# if null_for_empty = true, then a not existing neighbour is represented by 
	# a null in the array, if false, it is just ommited
	var neighbours = _get_surrounding_cells(cell, null_for_empty)
	
	var result = []
	for nb in neighbours:
		if nb == null:
			result.append(null)
		else:
			result.append(tilemap.get_cell_atlas_coords(0, nb))
	return result
		
func get_snap_position_in_screen_coords():
	
	var cell = tilemap.local_to_map(get_local_mouse_position())
	var used = tilemap.get_used_cells(0)

	if cell not in used:
		if len(used) == 0:
			if cell.x >= -1 and cell.x <= 1 and cell.y >= -1 and cell.y <= 1:
				var center = Vector2(cell.x*180+90, cell.y*180+90)
				return get_viewport_transform() * (global_transform * center)
		elif len(_get_surrounding_cells(cell, false)) > 0:
			var center = Vector2(cell.x*180+90, cell.y*180+90)
			return get_viewport_transform() * (global_transform * center)
	
	return Vector2(-1,-1)

func get_drop_cell():
	return tilemap.local_to_map(get_local_mouse_position())

func can_drop_in_cell(stone: Vector3i, cell: Vector2i):

	var used = tilemap.get_used_cells(0)
	
	if len(used) == 0:
		if cell.x >= -1 and cell.x <= 1 and cell[1] >= -1 and cell[1] <= 1:
			return true
	
	# cell must not be used already
	if cell in used:
		return false
		
	# must have neighbours
	var neighbours = _get_surrounding_stones(cell, false)
	if len(neighbours) == 0:
		return false
		
	# the neighbours need to be allowed! Must be:
	#   1. different colour, same symbol
	#   2. same colour, different symbol
	for nb in neighbours:
		if not ((nb[0] == stone[0] and nb[1] != stone[1]) or (nb[0] != stone[0] and nb[1] == stone[1])):
			return false

	# check all lines create to have correct symbol/color and no double
	for dir in [0,1]:
		var line_type = null # 0: same symbol, 1: same color
		for inc in [-1,1]:
			var next_cell = cell
			next_cell[dir] += inc
			while next_cell in used:
				var cell_stone = tilemap.get_cell_atlas_coords(0, next_cell) 
				
				# doubled?
				if cell_stone[0] == stone[0] and cell_stone[1] == stone[1]:
					return false
					
				# correct line_type?
				if line_type != null:
					if line_type == 1 and (cell_stone[0] != stone[0]):
						return false
					if line_type == 0 and (cell_stone[1] != stone[1]):
						return false
				else:
					if cell_stone[0] == stone[0]:
						line_type = 1
					else:
						line_type = 0
				
				next_cell[dir] += inc

	
	# and check if all stones we set up are within a line
	if len(round_cells)> 0:
		# either all x or all y are the same
		var line_dir: int
		if round_cells[0][0] == cell[0]:
			line_dir = 1
			for round_cell in round_cells:
				if round_cell[0] != cell[0]:
					return false
		# or all y are the same
		elif round_cells[0][1] == cell[1]:
			line_dir = 0
			for round_cell in round_cells:
				if round_cell[1] != cell[1]:
					return false
		else:
			return false
			
		# check if the line is continious, together with already existing stones
		var check_cells = round_cells.duplicate()
		for inc in [-1, 1]:
			var next_cell = cell
			next_cell[line_dir] += inc
			while next_cell in used:
				var idx = check_cells.find(next_cell)
				if idx >= 0:
					check_cells.remove_at(idx)
				next_cell[line_dir] += inc
		
		if len(check_cells) > 0:
			return false
		
	
	return true

func _calculate_line_points(cell: Vector2i, dir:int):
	# calculate the points in the line created. 0=horizontal, 1=vertical
	# note: cell must be used!
	
	var used = tilemap.get_used_cells(0)
	var points:int = 0

	var quirkle_points = 0
	for i in [-1,1]:
		# horizontal
		var next_cell = cell
		next_cell[dir] += i
		while next_cell in used:
			points += 1
			quirkle_points += 1
			next_cell[dir] += i

	# if the line is complete we get a quirkle!
	if quirkle_points == 5:
		points += 6
	
	if quirkle_points > 0: 
		# this is to prevent counting the cell alone in a line as point.
		# the stone only gives points if it connects something!
		points += 1
		
	return points

func calculate_round_points():
	# to calculate the round points we look at:
	# for multistone:
	# 	- all lines the stones created individual, except the multiline
	#   - calculate the multiline
	
	if len(round_cells) == 0:
		return 0
		
	if len(round_cells) == 1:
		# handle the special case of first round single stone drop
		if len(tilemap.get_used_cells(0)) == 1:
			return 1
		else:
			return _calculate_line_points(round_cells[0], 0) + _calculate_line_points(round_cells[0], 1)
		
	# we have multiple stones. First calculate the main direction to omit it for individual lines 
	# and to add it later
	var main_dir = 0
	var side_dir = 1
	if round_cells[0].x == round_cells[1].x:
		main_dir = 1
		side_dir = 0
		
	var points = 0
	for round_cell in round_cells:
		points += _calculate_line_points(round_cell, side_dir)
	
	points += _calculate_line_points(round_cells[0], main_dir)
	return points
	
