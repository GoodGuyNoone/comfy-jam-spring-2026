extends Area2D
class_name Pot

signal pot_selected(flower_id, flower_texture, start_global_position, is_filler)

@export var flower_id: String = ""
@export var flower_texture: Texture2D
@export var is_filler: bool = false
@export var pot_texture: Texture2D
@export var outline_color: Color

@onready var pot_sprite: Sprite2D = $PotSprite
@onready var flower_preview: Sprite2D = $FlowerPreview
@onready var outline_root: Node2D = $Outline


func _ready() -> void:
	flower_preview.texture = flower_texture
	flower_preview.visible = false
	pot_sprite.texture = pot_texture

	$Outline/O_Left.position = Vector2(-2, 0)
	$Outline/O_Right.position = Vector2(2, 0)
	$Outline/O_Up.position = Vector2(0, -2)
	$Outline/O_Down.position = Vector2(0, 2)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)

	outline_root.z_as_relative = true
	outline_root.z_index = -1

	for child in outline_root.get_children():
		if child is Sprite2D:
			child.texture = pot_texture
			child.visible = false
			child.modulate = outline_color
			child.z_as_relative = true
			child.z_index = 0


func _on_mouse_entered() -> void:
	print("mouse entered")
	for child in outline_root.get_children():
		if child is Sprite2D:
			child.visible = true


func _on_mouse_exited() -> void:
	for child in outline_root.get_children():
		if child is Sprite2D:
			child.visible = false


func _input_event(viewport, event, _shape_idx) -> void:
	if viewport.is_input_handled():
		return
	
	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return

	viewport.set_input_as_handled()
	pot_selected.emit(flower_id, flower_texture, global_position, is_filler)
