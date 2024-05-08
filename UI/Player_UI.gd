extends PanelContainer

@export var player_name: String = "Unknown"
@export var points: int = 0

signal dragged(StoneUI, Rect2)
signal dropped(StoneUI)

@onready var stone_area = $VBoxContainer/StoneContainer/StoneAreaUi
@onready var name_node = $VBoxContainer/Name
@onready var point_node = $VBoxContainer/StoneContainer/VBoxContainer/Points

# Called when the node enters the scene tree for the first time.
func _ready():
	
	stone_area.dragged.connect(_on_dragged)
	stone_area.dropped.connect(_on_dropped)
	
	# test code
	if false:
		stone_area.add_stone(Vector3i(0,4,0))
		stone_area.add_stone(Vector3i(3,1,0))
		stone_area.add_stone(Vector3i(2,4,0))
		
		set_active(true)
		
func _process(_delta):
	name_node.text = player_name
	point_node.text = str(points)

func set_active(active: bool):
	stone_area.local_drag_only = !active
	
	# colour the border!
	var color = Color("#1f2b3c")
	if active:
		color = Color(1,0,0)
	
	var style_box: StyleBoxFlat = get_theme_stylebox("panel")
	style_box.border_color = color
	add_theme_stylebox_override("panel", style_box)

func add_stone(stone: Vector3i):
	stone_area.add_stone(stone)
	
func remove_stone(stone: Vector3i):
	stone_area.remove_stone(stone)
	
func get_stone_count():
	# calculate how much stones we currently hold
	return stone_area.get_stone_count()

func get_drag_position_offset():
	return stone_area.global_position - global_position

func get_stone_size():
	return stone_area.get_stone_size()

func _on_dragged(stone: StoneUI, rect: Rect2):
	# convert rect to PlayerUI coord
	var delta = stone_area.global_position - global_position
	var new_rect = Rect2(rect.position + delta, rect.size)
	dragged.emit(stone, new_rect)

func _on_dropped(stone:StoneUI):
	dropped.emit(stone)
