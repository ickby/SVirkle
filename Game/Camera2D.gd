class_name CameraPanZoom
extends Camera2D

# Lower cap for the `_zoom_level`.
@export var min_zoom := 0.2
# Upper cap for the `_zoom_level`.
@export var max_zoom := 2.0
# Controls how much we increase or decrease the `_zoom_level` on every turn of the scroll wheel.
@export var zoom_factor := 0.1
# Duration of the zoom's tween animation.
@export var zoom_duration := 0.2

# The camera's target zoom level.
var _zoom_level := 1.0:
	get:
		return _zoom_level
	set(value):
		_zoom_level = value

var tween: Tween

# Called when the node enters the scene tree for the first time.
func _ready():
	pass

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):
	pass

func _set_zoom_level(value: float) -> void:
	# We limit the value between `min_zoom` and `max_zoom`
	_zoom_level = clamp(value, min_zoom, max_zoom)
	#zoom = Vector2(_zoom_level, _zoom_level)
	tween = create_tween()
	tween.tween_property(
		self,
		"zoom",
		Vector2(_zoom_level, _zoom_level),
		zoom_duration).set_trans(
		tween.TRANS_SINE).set_ease(tween.EASE_OUT)
	

	
func _unhandled_input(event):
	if event.is_action_pressed("zoom_in"):
		_set_zoom_level(_zoom_level- zoom_factor)
		
	if event.is_action_pressed("zoom_out"):
		_set_zoom_level(_zoom_level + zoom_factor)

	if event is InputEventMouseMotion:
		if Input.is_action_pressed("pan"):
			position -= (event.relative/zoom)
	
