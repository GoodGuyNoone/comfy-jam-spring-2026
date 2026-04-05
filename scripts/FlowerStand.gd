extends Node2D

signal flower_selected(flower_id, flower_texture, start_global_position)

func _ready() -> void:
	for child in get_children():
		if child.has_signal("picked"):
			child.picked.connect(_on_flower_selected)

func _on_flower_selected(flower_id: StringName, flower_texture: Texture2D, start_global_position: Vector2) -> void:
	flower_selected.emit(flower_id, flower_texture, start_global_position)