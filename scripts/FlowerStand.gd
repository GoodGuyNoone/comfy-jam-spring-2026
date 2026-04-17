extends Node2D

signal flower_selected(flower_id, flower_texture, start_global_position, is_filler)


func _ready() -> void:
	for child in get_children():
		if child.has_signal("pot_selected"):
			child.pot_selected.connect(_on_pot_selected)


func _on_pot_selected(flower_id: StringName, flower_texture: Texture2D, start_global_position: Vector2, is_filler: bool) -> void:
	flower_selected.emit(flower_id, flower_texture, start_global_position, is_filler)
