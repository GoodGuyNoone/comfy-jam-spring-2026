extends Area2D

signal picked(flower_id, flower_texture, start_global_position, is_filler)
signal remove_requested(flower_id, flower_texture, flower_node)
signal vase_hover_entered(flower_node)
signal vase_hover_exited(flower_node)

@export var flower_id: String = ""
@export var can_be_picked: bool = true
@export var can_be_removed: bool = false
@export var flower_texture: Texture2D
@export var outline_color: Color
@export var is_filler: bool = false

@onready var sprite: Sprite2D = $Sprite2D
@onready var outline: Node2D = $Outline
@onready var collision_main: CollisionShape2D = $CollisionMain
@onready var collision_filler: CollisionShape2D = $CollisionFiller

var is_selected_for_removal: bool = false


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

	collision_main.disabled = is_filler
	collision_filler.disabled = not is_filler

	if is_inside_tree():
		_apply_visuals()
	else:
		call_deferred("_apply_visuals")


func _apply_visuals() -> void:
	if has_node("Sprite2D"):
		$Sprite2D.texture = flower_texture
		$Sprite2D.z_as_relative = true
		$Sprite2D.z_index = 0
	
	if has_node("Outline"):
		var outline_root: Node2D = $Outline
		outline_root.z_as_relative = true
		outline_root.z_index = -1

		for child in outline_root.get_children():
			if child is Sprite2D:
				child.texture = flower_texture
				child.visible = false
				child.modulate = outline_color
				child.z_as_relative = true
				child.z_index = 0


func _on_mouse_entered() -> void:
	if can_be_removed:
		vase_hover_entered.emit(self)


func _on_mouse_exited() -> void:
	if can_be_removed:
		vase_hover_exited.emit(self)


func set_selected_for_removal(value: bool) -> void:
	is_selected_for_removal = value

	if has_node("Outline"):
		var outline_root: Node2D = $Outline
		outline_root.z_as_relative = true
		outline_root.z_index = -1

		for child in outline_root.get_children():
			if child is Sprite2D:
				child.visible = value

func _input_event(viewport, event, _shape_idx) -> void:
	if viewport.is_input_handled():
		return

	if not (event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT):
		return

	if can_be_picked:
		viewport.set_input_as_handled()
		picked.emit(flower_id, flower_texture, global_position, is_filler)
		return

	if can_be_removed:
		if not is_selected_for_removal:
			return

		if not can_remove_during_tutorial():
			return

		viewport.set_input_as_handled()
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
