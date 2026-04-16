extends Area2D
class_name Pot

signal pot_selected(flower_id, flower_texture, start_global_position, is_filler)

@export var flower_id: String = ""
@export var flower_texture: Texture2D
@export var is_filler: bool = false
@export var pot_texture: Texture2D

@onready var pot_sprite: Sprite2D = $PotSprite
@onready var flower_preview: Sprite2D = $FlowerPreview

func _ready() -> void:
	flower_preview.texture = flower_texture
	flower_preview.visible = false
	pot_sprite.texture = pot_texture


func _input_event(viewport, event, _shape_idx) -> void:
	if viewport.is_input_handled():
		return
	
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return

	viewport.set_input_as_handled()
	pot_selected.emit(flower_id, flower_texture, global_position, is_filler)
