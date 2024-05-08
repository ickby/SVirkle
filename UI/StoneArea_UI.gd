extends Control

@export var margin:int = 5
@export var local_drag_only: bool = false
signal dragged(StoneUI, Rect2)
signal dropped(StoneUI)

# general variables
var stone_ui: Array[StoneUI] = []

# drag and drop variables
var drag: bool = false
var drag_test: bool = false 
var drag_position: Vector2
var drag_ui: StoneUI

func add_stone(stone: Vector3i):
	# find the next unused UI
	for ui in stone_ui:
		if not ui.enabled:
			ui.stone = stone
			ui.enabled = true  
			
			# a nice little animation
			
			break 

func remove_stone(stone: Vector3i):
	for ui in stone_ui:
		if ui.stone == stone:
			ui.enabled = false

# Returns the amount of stones currently available inthe area
func get_stone_count():
	var count = 0
	for ui in stone_ui:
		if ui.enabled:
			count += 1
			
	return count

func get_stone_size():
	return min(self.size.y-2*margin, (self.size.x-margin*7)/6)
	
# Called when the node enters the scene tree for the first time.
func _ready():
	
	var stone_ui_scene = load("res://UI/Stone_UI.tscn")
	for i in range(6):
		var stone_node = stone_ui_scene.instantiate()
		add_child(stone_node)
		stone_node.enabled = false
		stone_ui.push_front(stone_node)
		
		stone_node.set_multiplayer_authority(get_multiplayer_authority())

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta):
	
	var stone_size = get_stone_size()
	var position_x = margin + stone_size/2
	var position_y = margin + (self.size.y-2*margin-stone_size)/2 + stone_size/2
	for ui in stone_ui:
		if ui != drag_ui and not ui.fixed:
			ui.size = lerp(ui.size, int(stone_size), delta*10)
			ui.position = lerp(ui.position, Vector2(position_x, position_y), delta*10)
		
		position_x += stone_size + 5

func _get_target_rect(ui) -> Rect2:
	# calculates the position rect of the target pos, ignoring all animations
	var idx = stone_ui.find(ui)
	var position_x = margin + (ui.size + margin)*idx
	var position_y = margin + (self.size.y-2*margin-ui.size)/2
	
	return Rect2(Vector2(position_x, position_y), Vector2(ui.size, ui.size))

func _get_current_rect(ui) -> Rect2:
	# get the rect or the uis current position, hence including all animations etc.
	return Rect2(ui.position-Vector2(ui.size,ui.size)/2, Vector2(ui.size, ui.size))


func _gui_input(event):
	
	if not is_multiplayer_authority():
		return
	
	if event.is_action_pressed("drag"):
		drag_position = get_local_mouse_position()
		for ui in stone_ui:
			if _get_target_rect(ui).has_point(drag_position):
				drag_ui = ui
				drag_test = true
				break
	
	if event.is_action_released("drag"):
		
		if drag and not local_drag_only:
			dropped.emit(drag_ui)
		
		drag = false
		drag_test = false
		drag_ui = null
	
	if drag_test and event is InputEventMouseMotion:
		var distance = drag_position.distance_to(get_local_mouse_position())
		if distance > 5:
			drag_test = false
			drag = true

	if drag and event is InputEventMouseMotion:
		var delta = drag_position - get_local_mouse_position()
		drag_position = get_local_mouse_position()
		
		if local_drag_only:
			# horizontal only
			drag_ui.position.x -= delta.x
			# make sure to no leave the boundaries
			if drag_ui.position.x < (margin + drag_ui.size/2):
				drag_ui.position.x = margin + drag_ui.size/2
			elif drag_ui.position.x > (size.x-margin-drag_ui.size/2):
				drag_ui.position.x = size.x-margin-drag_ui.size/2
		else:
			drag_ui.position -= delta

		var drag_rect = _get_current_rect(drag_ui)
		
		# inform about the drag
		if not local_drag_only:
			dragged.emit(drag_ui, drag_rect)
		
		# reorder the other ui's if needed
		for ui in stone_ui:
			if ui == drag_ui:
				continue

			var intersect_area = _get_target_rect(ui).intersection(drag_rect).get_area()

			if intersect_area/drag_rect.get_area() > 0.5:
				
				# we need to move! find out in which direction the empty slot is
				var idx_drag = stone_ui.find(drag_ui)
				var idx_move = stone_ui.find(ui)
				
				if not ui.enabled:
					# if not enabled simply swap
					stone_ui[idx_drag] = ui
					stone_ui[idx_move] = drag_ui				
				elif idx_drag < idx_move:
					stone_ui.remove_at(idx_drag)
					stone_ui.insert(idx_move, drag_ui)
				else:
					stone_ui.remove_at(idx_drag)
					stone_ui.insert(idx_move, drag_ui)

