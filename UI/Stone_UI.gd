class_name StoneUI
extends Node2D

@export var size: int = 180
@export var stone: Vector3i = Vector3i(0,0,0)
@export var enabled: bool = true
@export var fixed: bool = false

@onready var sprite: Sprite2D = $Sprite
@onready var timer: Timer = $Timer

# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(_delta):

	scale = Vector2(size, size)/180
	sprite.texture.region = Rect2(180*stone[0], 180*stone[1], 180, 180)
	
	visible = enabled
	sprite.visible = is_multiplayer_authority()

func set_fixed():
	
	fixed = true
	timer.one_shot = true
	timer.timeout.connect(_on_timeout)
	timer.start(1)
	
func _on_timeout():
	fixed = false
