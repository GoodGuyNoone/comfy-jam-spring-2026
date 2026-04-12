extends Area2D

signal picked(flower_id, flower_texture, start_global_position, is_filler)
signal remove_requested(flower_id, flower_texture, flower_node)

@export var flower_id: String = ""
@export var can_be_picked: bool = true
@export var can_be_removed: bool = false
@export var flower_texture: Texture2D
@export var outline_color: Color
@export var is_filler: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var outline: Node2D = $Outline


func _ready() -> void:
	_apply_visuals()
	$Outline/O_Left.position = Vector2(-1, 0)
	$Outline/O_Right.position = Vector2(1, 0)
	$Outline/O_Up.position = Vector2(0, -1)
	$Outline/O_Down.position = Vector2(0, 1)

	mouse_entered.connect(_on_mouse_entered)
	mouse_exited.connect(_on_mouse_exited)


func setup(id: String, tex: Texture2D, pickable: bool, removable: bool, filler: bool = false) -> void:
	flower_id = id
	flower_texture = tex
	can_be_picked = pickable
	can_be_removed = removable
	is_filler = filler

	if is_inside_tree():
		_apply_visuals()
	else:
		call_deferred("_apply_visuals")


func _apply_visuals() -> void:
	sprite.texture = flower_texture
	
	for child in outline.get_children():
		child.texture = flower_texture
		child.modulate = outline_color
		child.visible = false
		child.z_index = -1


func _on_mouse_entered() -> void:
	if can_be_removed:
		for child in outline.get_children():
			child.visible = true


func _on_mouse_exited() -> void:
	for child in outline.get_children():
		child.visible = false


func _input_event(viewport, event, _shape_idx) -> void:
	if viewport.is_input_handled():
		return

	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return
	
	viewport.set_input_as_handled()

	if can_be_picked:
		picked.emit(flower_id, flower_texture, global_position, is_filler)
		return

	if can_be_removed:
		if not can_remove_during_tutorial():
			return
		remove_requested.emit(flower_id, flower_texture, self)


func can_remove_during_tutorial() -> bool:
	var main := get_tree().current_scene
	if main == null:
		return true

	var game_manager = main.get_node_or_null("GameManager")
	if game_manager == null:
		return true

	if game_manager.has_method("tutorial_blocks_remove_flower"):
		return not game_manager.tutorial_blocks_remove_flower()

	return true
