extends Node2D

signal flower_removed(flower_id)

var current_flowers: Array = []
var slots: Array[Marker2D] = []
var main_slot_indices: Array[int] = []
var filler_slot_indices: Array[int] = []
var current_phase = "main"

var slot_rotations = [-15.0, 15.0, -30.0, 0.0, 30.0, -17.0, 17.0, -15.0, 15.0, 0]
var slot_z_indexes = [1, 1, 2, 2, 2, 3, 3, 0, 0, 0]

# @export var flower_scene: PackedScene

@onready var slots_root: Node2D = $Slots
@onready var flowers_container: Node2D = $FlowersContainer
@onready var main_slots: Node2D = $Slots/MainSlots
@onready var filler_slots: Node2D = $Slots/FillerSlots


func _ready() -> void:
	_collect_slots()

	current_flowers.resize(slots.size())

	for i in range(current_flowers.size()):
		current_flowers[i] = null


func _collect_slots() -> void:
	slots.clear()
	main_slot_indices.clear()
	filler_slot_indices.clear()

	for child in main_slots.get_children():
		if child is Marker2D:
			main_slot_indices.append(slots.size())
			slots.append(child)
	
	for child in filler_slots.get_children():
		if child is Marker2D:
			filler_slot_indices.append(slots.size())
			slots.append(child)


func set_phase(phase: StringName) -> void:
	current_phase = phase


func get_phase_slot_indices(phase: StringName) -> Array[int]:
	if phase == "main":
		return main_slot_indices
	if phase == "filler":
		return filler_slot_indices
	return []


func get_next_free_slot_index_for_phase(phase: StringName) -> int:
	var allowed_slots := get_phase_slot_indices(phase)

	for slot_index in allowed_slots:
		if slot_index < current_flowers.size() and current_flowers[slot_index] == null:
			return slot_index

	return -1


func has_free_slot_for_phase(phase: StringName) -> bool:
	return get_next_free_slot_index_for_phase(phase) != -1


func get_next_slot_global_position_for_phase(phase: StringName) -> Vector2:
	var index := get_next_free_slot_index_for_phase(phase)
	if index == -1:
		return global_position
	return slots[index].global_position


func get_next_slot_rotation_for_phase(phase: StringName) -> float:
	var index := get_next_free_slot_index_for_phase(phase)
	if index == -1:
		return 0.0
	if index >= slot_rotations.size():
		return 0.0
	return slot_rotations[index]
		

func finalize_flower_for_phase(flower_instance: Area2D, flower_id: StringName, flower_texture: Texture2D, is_filler: bool, phase: StringName) -> void:
	var index := get_next_free_slot_index_for_phase(phase)

	if index == -1:
		push_error("finalize_flower_for_phase: no free slot left for phase " + phase)
		if is_instance_valid(flower_instance):
			flower_instance.queue_free()
		return

	var target_slot := slots[index]
	var final_global := flower_instance.global_position

	if flower_instance.get_parent():
		flower_instance.get_parent().remove_child(flower_instance)

	flowers_container.add_child(flower_instance)
	flower_instance.global_position = final_global
	flower_instance.position = target_slot.position
	flower_instance.rotation_degrees = slot_rotations[index]
	flower_instance.z_index = slot_z_indexes[index]
	flower_instance.setup(flower_id, flower_texture, false, true, is_filler)
	flower_instance.set_meta("slot_index", index)
	flower_instance.set_meta("phase", phase)

	if not flower_instance.remove_requested.is_connected(_on_flower_remove_requested):
		flower_instance.remove_requested.connect(_on_flower_remove_requested)

	current_flowers[index] = {
		"id": flower_id,
		"texture": flower_texture,
		"node": flower_instance,
		"slot_index": index,
		"is_filler": is_filler,
		"phase": phase
	}

func clear_vase() -> void:
	if flowers_container == null:
		push_error("clear_vase: flowers_container is null")
		return

	for child in flowers_container.get_children():
		child.queue_free()

	current_flowers.resize(slots.size())

	for i in range(current_flowers.size()):
		current_flowers[i] = null

	current_phase = "main"

func get_flowers() -> Array[StringName]:
	var ids: Array[StringName] = []

	for flower_data in current_flowers:
		if flower_data != null:
			ids.append(flower_data["id"])

	return ids

func get_flowers_for_phase(phase: StringName) -> Array[StringName]:
	var ids: Array[StringName] = []

	for flower_data in current_flowers:
		if flower_data != null and flower_data["phase"] == phase:
			ids.append(flower_data["id"])

	return ids

func _on_flower_remove_requested(flower_id: StringName, _flower_texture: Texture2D, flower_node: Node) -> void:
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


func finalize_flower(flower_instance: Area2D, flower_id: StringName, flower_texture: Texture2D) -> void:
	var index := get_next_free_slot_index()

	if index == -1:
		push_error("finalize_flower: no free slot left")
		if is_instance_valid(flower_instance):
			flower_instance.queue_free()
		return
	
	var target_slot := slots[index]
	var final_global := flower_instance.global_position
	var base_rot = slot_rotations[index]
	var variation = randf_range(-5.0, 5.0)

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
