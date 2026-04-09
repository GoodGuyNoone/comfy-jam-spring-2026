extends Node2D

signal flower_removed(flower_id)

var current_flowers: Array = []
var slots: Array[Marker2D] = []

var slot_rotations = [0.0, -7.0, 7.0, -12.0, 5.0, 12.0, -10.0, 10.0, -5.0]
var slot_z_indexes = [0, 1, 1, 2, 2, 2, 3, 3, 3]

# @export var flower_scene: PackedScene

@onready var slots_root: Node2D = $Slots
@onready var flowers_container: Node2D = $FlowersContainer


func _ready() -> void:
	slots.clear()

	for child in slots_root.get_children():
		if child is Marker2D:
			slots.append(child)
	
	current_flowers.resize(slots.size())

	for i in range(current_flowers.size()):
		current_flowers[i] = null


func get_capacity() -> int:
	return slots.size()


func is_full() -> bool:
	if get_next_free_slot_index() == -1:
		print("vase is full")
	else:
		print("vase is not full")
	return get_next_free_slot_index() == -1


func get_next_slot_global_position() -> Vector2:
	var slot_index := get_next_free_slot_index()
	if slot_index == -1:
		return global_position
	return slots[slot_index].global_position


func get_next_free_slot_index() -> int:
	for i in range(current_flowers.size()):
		if current_flowers[i] == null:
			return i
	return -1


func get_next_slot_rotation() -> float:
	var index := get_next_free_slot_index()
	if index == -1:
		return 0.0
	if index >= slot_rotations.size():
		return 0.0
	return slot_rotations[index]


func finalize_flower(flower_instance: Area2D, flower_id: String, flower_texture: Texture2D) -> void:
	var index := get_next_free_slot_index()

	if index == -1:
		push_error("finalize_flower: no free slot left")
		if is_instance_valid(flower_instance):
			flower_instance.queue_free()
		return
	
	var target_slot := slots[index]
	var final_global := flower_instance.global_position
	var base_rot = slot_rotations[index]
	var variation = randf_range(-2.0, 2.0)

	if flower_instance.get_parent():
		flower_instance.get_parent().remove_child(flower_instance)
	
	flowers_container.add_child(flower_instance)
	flower_instance.global_position = final_global
	flower_instance.position = target_slot.position
	flower_instance.rotation_degrees = base_rot + variation
	flower_instance.z_index = slot_z_indexes[index]
	flower_instance.setup(flower_id, flower_texture, false, true)
	flower_instance.set_meta("slot_index", index)

	if not flower_instance.remove_requested.is_connected(_on_flower_remove_requested):
		flower_instance.remove_requested.connect(_on_flower_remove_requested)

	current_flowers[index] = {
		"id": flower_id,
		"texture": flower_texture,
		"node": flower_instance,
		"slot_index": index,
	}


func clear_vase() -> void:
	if flowers_container == null:
		push_error("clear_vase: flower_container is null")
		return
	
	for child in flowers_container.get_children():
		child.queue_free()

	current_flowers.resize(slots.size())

	for i in range(current_flowers.size()):
		current_flowers[i] = null


func get_flowers() -> Array[StringName]:
	var ids: Array[StringName] = []

	for flower_data in current_flowers:
		ids.append(flower_data["id"])

	return ids


func _on_flower_remove_requested(flower_id: String, _flower_texture: Texture2D, flower_node: Node) -> void:
	if not flower_node.has_meta("slot_index"):
		return

	var slot_index: int = flower_node.get_meta("slot_index")
	remove_flower_at(slot_index)
	flower_removed.emit(flower_id)


func remove_flower_at(index: int) -> void:
	if index < 0 or index >= current_flowers.size():
		return
	
	var flower_data = current_flowers[index]
	if flower_data == null:
		return
	
	var flower_node: Node = flower_data["node"]

	if is_instance_valid(flower_node):
		flower_node.queue_free()
	
	current_flowers[index] = null
