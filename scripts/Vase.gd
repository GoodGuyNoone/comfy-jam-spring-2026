extends Node2D

signal flower_removed(flower_id)
signal single_flower_removed(flower_id)

var current_flowers: Array = []
var slots: Array[Marker2D] = []
var current_phase = "main"
var current_layout_size: int = 10

# var slot_rotations = [-15.0, 15.0, -30.0, 0.0, 30.0, -17.0, 17.0, -15.0, 15.0, 0]
# var slot_z_indexes = [1, 1, 2, 2, 2, 3, 3, 0, 0, 0]


@onready var flowers_container: Node2D = $FlowersContainer
@onready var layouts: Node2D = $Layouts


func _ready() -> void:
	set_layout_size(current_layout_size)


func set_layout_size(layout_size: int) -> void:
	current_layout_size = layout_size
	_collect_slots_for_layout(layout_size)

	current_flowers.resize(slots.size())

	for i in range(current_flowers.size()):
		current_flowers[i] = null


func _collect_slots_for_layout(layout_size: int) -> void:
	slots.clear()

	var layout_node_name := "%d" % layout_size

	var layout_node := layouts.get_node(layout_node_name)

	for child in layout_node.get_children():
		if child is BouquetSlot:
			slots.append(child)



func set_phase(phase: StringName) -> void:
	current_phase = phase


func get_slot_indices_for_phase(phase: StringName) -> Array[int]:
	var result: Array[int] = []

	for i in range(slots.size()):
		if slots[i].slot_type == phase:
			result.append(i)

	return result


func get_next_free_slot_index_for_phase(phase: StringName) -> int:
	var allowed_slots := get_slot_indices_for_phase(phase)

	for slot_index in allowed_slots:
		if current_flowers[slot_index] == null:
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
	return slots[index].slot_rotation
		

func finalize_flower_for_phase(flower_instance: Area2D, flower_id: StringName, flower_texture: Texture2D, is_filler: bool, phase: StringName) -> void:
	var index := get_next_free_slot_index_for_phase(phase)

	if index == -1:
		push_error("No free slot for phase " + phase)
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
	flower_instance.rotation_degrees = target_slot.slot_rotation
	flower_instance.z_index = target_slot.slot_z_index
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
	single_flower_removed.emit(flower_id)


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
