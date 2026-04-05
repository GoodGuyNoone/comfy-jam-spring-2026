extends Node

@export var flower_scene: PackedScene

@onready var flower_stand: Node2D = $'../FlowerStand'
@onready var vase = $'../Vase'
@onready var moving_flowers = $'../MovingFlowers'

var is_animating: bool = false

func _ready() -> void:
	flower_stand.flower_selected.connect(_on_flower_selected)

func _on_flower_selected(flower_id: String, flower_texture: Texture2D, start_global_position: Vector2) -> void:
	if is_animating:
		return
	
	if vase.is_full():
		return
	
	is_animating = true

	var flower_instance = flower_scene.instantiate()
	moving_flowers.add_child(flower_instance)
	flower_instance.setup(flower_id, flower_texture, false)
	flower_instance.global_position = start_global_position

	var target_global_position: Vector2 = vase.get_next_slot_global_position()

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(flower_instance, "global_position", target_global_position, 0.25)
	tween.parallel().tween_property(flower_instance, "rotation", deg_to_rad(randf_range(-4.0, 4.0)), 0.25)
	tween.parallel().tween_property(flower_instance, "scale", Vector2(1.05, 1.05), 0.12)
	tween.tween_property(flower_instance, "scale", Vector2.ONE, 0.13)

	await tween.finished

	vase.finalize_flower(flower_instance, flower_id)
	is_animating = false
