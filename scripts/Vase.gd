extends Node2D

var current_flowers: Array[StringName] = []
var slots: Array[Marker2D] = []

@onready var slots_root: Node2D = $Slots
@onready var flowers_container: Node2D = $FlowersContainer

func _ready() -> void:
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

func finalize_flower(flower_instance: Node2D, flower_id: String) -> void:
	var target_slot_index := current_flowers.size()
	var target_slot := slots[target_slot_index]

	var final_global := flower_instance.global_position

	if flower_instance.get_parent():
		flower_instance.get_parent().remove_child(flower_instance)
	
	flowers_container.add_child(flower_instance)
	flower_instance.global_position = final_global
	flower_instance.position = target_slot.position

	current_flowers.append(flower_id)

func clear_vase() -> void:
	for child in flowers_container.get_children():
		child.queue_free()
	current_flowers.clear()

func get_flowers() -> Array[StringName]:
	return current_flowers.duplicate()
