extends Node2D

var current_flowers: Array[Dictionary] = []
var slots: Array[Marker2D] = []
var slot_rotations = [0.0, -8.0, 8.0, -14.0, 14.0]

@export var flower_scene: PackedScene

@onready var slots_root: Node2D = $Slots
@onready var flowers_container: Node2D = $FlowersContainer


func _ready() -> void:
	print("flowers_container:", flowers_container)
	for child in slots_root.get_children():
		if child is Marker2D:
			slots.append(child)


func is_full() -> bool:
	if current_flowers.size() >= slots.size():
		print("vase is full")
	else:
		print("vase is not full")
	return current_flowers.size() >= slots.size()


func get_next_slot_global_position() -> Vector2:
	var slot_index := current_flowers.size()
	return slots[slot_index].global_position


func get_next_slot_rotation() -> float:
	var index := current_flowers.size()
	if index >= slot_rotations.size():
		return 0.0
	return slot_rotations[index]


func finalize_flower(flower_instance: Node2D, flower_id: String, flower_texture: Texture2D) -> void:
	var target_slot_index := current_flowers.size()
	var target_slot := slots[target_slot_index]
	var index := current_flowers.size()
	var final_global := flower_instance.global_position
	var base_rot = slot_rotations[index]
	var variation = randf_range(-2.0, 2.0)

	if flower_instance.get_parent():
		flower_instance.get_parent().remove_child(flower_instance)
	
	flowers_container.add_child(flower_instance)
	flower_instance.global_position = final_global
	flower_instance.position = target_slot.position
	flower_instance.rotation_degrees = base_rot + variation

	flower_instance.setup(flower_id, flower_texture, false, true)
	flower_instance.remove_requested.connect(_on_flower_remove_requested)

	current_flowers.append({
		"id": flower_id,
		"texture": flower_texture
	})


func clear_vase() -> void:
	for child in flowers_container.get_children():
		child.queue_free()

	current_flowers.clear()


func get_flowers() -> Array[StringName]:
	var ids: Array[StringName] = []
	for flower_data in current_flowers:
		ids.append(flower_data["id"])
	return ids


func _on_flower_remove_requested(_flower_id: String, _flower_texture: Texture2D, flower_node: Node) -> void:
	var index := flower_node.get_index()
	remove_flower_at(index)


func remove_flower_at(index: int) -> void:
	if index < 0 or index >= current_flowers.size():
		return
	
	current_flowers.remove_at(index)
	_rebuild_vase_visuals()


func _rebuild_vase_visuals() -> void:
	for child in flowers_container.get_children():
		child.queue_free()
	
	for i in range(current_flowers.size()):
		var flower_data = current_flowers[i]
		var flower_instance = flower_scene.instantiate()
		flowers_container.add_child(flower_instance)
		flower_instance.position = slots[i].position
		flower_instance.setup(flower_data["id"], flower_data["texture"], false, true)
		flower_instance.remove_requested.connect(_on_flower_remove_requested)
