extends Node2D

@export var leaf_scene: PackedScene
@export var spawn_interval := 1.2
@export var max_leaves := 6

var screen_size: Vector2
var timer := 0.0

func _ready() -> void:
	screen_size = get_viewport().get_visible_rect().size

func _process(delta: float) -> void:
	timer -= delta
	if timer > 0.0:
		return
	
	timer = randf_range(spawn_interval * 0.8, spawn_interval * 1.2)
	
	if get_child_count() >= max_leaves:
		return
	
	_spawn_leaf()

func _spawn_leaf() -> void:
	var leaf := leaf_scene.instantiate()
	add_child(leaf)
	
	leaf.global_position = Vector2(
		screen_size.x + randf_range(20.0, 120.0),
		randf_range(-20.0, screen_size.y * 0.8)
	)
	
	leaf.speed = randf_range(60.0, 100.0)
	leaf.drift = randf_range(8.0, 20.0)
	leaf.rotation_speed = randf_range(-0.8, 0.8)
	leaf.scale = Vector2.ONE * randf_range(0.7, 1.2)