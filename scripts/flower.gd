extends Area2D

signal picked(flower_id, flower_texture, start_global_position)

@export var flower_id: String = ""
@export var can_be_picked: bool = true
@export var flower_texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
	sprite.texture = flower_texture

func setup(id: String, tex: Texture2D, pickable: bool) -> void:
	flower_id = id
	can_be_picked = pickable
	flower_texture = tex
	sprite.texture = flower_texture

func _input_event(_viewport, event, _shape_idx) -> void:
	if not can_be_picked:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		picked.emit(flower_id, sprite.texture, global_position)
		print("emits flower_id: %s" % flower_id)
