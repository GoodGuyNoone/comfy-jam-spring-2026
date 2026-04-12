extends Node

@export var flower_scene: PackedScene

var available_main_flowers: Array[StringName] = []
var available_filler_flowers: Array[StringName] = []

var current_main_order: Array[StringName] = []
var current_filler_order: Array[StringName] = []

var current_phase: String = "main"
var is_animating: bool = false
var order_index: int = 0

@onready var flower_stand = get_parent().get_node("FlowerStand")
@onready var vase = get_parent().get_node("Vase")
@onready var moving_flowers = get_parent().get_node("MovingFlowers")
@onready var order_label: Label = get_parent().get_node("UI/OrderLabel")
@onready var submit_button: Button = get_parent().get_node("UI/SubmitButton")
@onready var clear_button: Button = get_parent().get_node("UI/ClearVaseButton")
@onready var feedback_label: Label = get_parent().get_node("UI/FeedbackLabel")


func _ready() -> void:
	randomize()

	flower_stand.flower_selected.connect(_on_flower_selected)
	submit_button.pressed.connect(_on_submit_pressed)
	clear_button.pressed.connect(_on_clear_pressed)
	
	if vase.has_signal("flower_removed"):
		vase.flower_removed.connect(_on_vase_flower_removed)

	collect_available_flowers_from_stand()
	order_index += 1
	call_deferred("start_round")


func start_round() -> void:
	print("order: ", order_index)

	current_phase = "main"
	vase.set_phase("main")
	vase.clear_vase()

	var main_count : int
	var filler_count : int

	# if order_index <= 2:
	# 	main_count = 3
	# 	filler_count = 2
	# elif order_index <= 5:
	# 	main_count = 5
	# 	filler_count = 2
	# else:
	main_count = 7
	filler_count = 3
	
	current_main_order = generate_order(available_main_flowers, main_count)
	current_filler_order = generate_order(available_filler_flowers, filler_count)

	var layout_size := main_count + filler_count
	print("layout set to:" + str(layout_size))
	vase.set_layout_size(layout_size)

	feedback_label.text = ""
	refresh_phase_state()
	update_receipt_ui()
	update_submit_state()


func collect_available_flowers_from_stand() -> void:
	available_main_flowers.clear()
	available_filler_flowers.clear()

	for child in flower_stand.get_children():
		if child.flower_id == "":
			continue

		if child.is_filler:
			if not available_filler_flowers.has(child.flower_id):
				available_filler_flowers.append(child.flower_id)
		else:
			if not available_main_flowers.has(child.flower_id):
				available_main_flowers.append(child.flower_id)


func generate_order(pool: Array[StringName], count: int) -> Array[StringName]:
	var order: Array[StringName] = []

	for i in range(count):
		var random_index := randi() % pool.size()
		order.append(pool[random_index])

	return order


func get_required_main_count() -> int:
	return current_main_order.size()


func get_required_filler_count() -> int:
	return current_filler_order.size()


func get_current_main_count() -> int:
	return vase.get_flowers_for_phase("main").size()


func get_current_filler_count() -> int:
	return vase.get_flowers_for_phase("filler").size()


func are_main_slots_filled() -> bool:
	return get_current_main_count() >= get_required_main_count()


func is_full_bouquet_built() -> bool:
	return get_current_main_count() >= get_required_main_count() and get_current_filler_count() >= get_required_filler_count()


func refresh_phase_state() -> void:
	if are_main_slots_filled():
		current_phase = "filler"
	else:
		current_phase = "main"

	vase.set_phase(current_phase)


func update_submit_state() -> void:
	submit_button.disabled = not is_full_bouquet_built()


func update_receipt_ui() -> void:
	var text := ""

	text += "Main (%d/%d): " % [get_current_main_count(), get_required_main_count()]
	for flower in current_main_order:
		text += flower + " "

	text += "\n"

	if current_phase == "main":
		text += "Fillers (locked"
		if get_current_filler_count() > 0:
			text += ", placed: %d/%d" % [get_current_filler_count(), get_required_filler_count()]
		text += "): "
	else:
		text += "Fillers (%d/%d): " % [get_current_filler_count(), get_required_filler_count()]

	for flower in current_filler_order:
		text += flower + " "

	order_label.text = text


func _on_flower_selected(flower_id: String, flower_texture: Texture2D, start_global_position: Vector2, is_filler: bool) -> void:
	if is_animating:
		return

	refresh_phase_state()

	if current_phase == "main" and is_filler:
		feedback_label.text = "Place main flowers first"
		return

	if current_phase == "filler" and not is_filler:
		feedback_label.text = "Main flowers already filled"
		return

	if not vase.has_free_slot_for_phase(current_phase):
		feedback_label.text = "No free slots for this phase"
		return

	is_animating = true
	feedback_label.text = ""

	var flower_instance = flower_scene.instantiate()
	moving_flowers.add_child(flower_instance)
	flower_instance.setup(flower_id, flower_texture, false, false, is_filler)
	flower_instance.global_position = start_global_position

	var target_global_position: Vector2 = vase.get_next_slot_global_position_for_phase(current_phase)
	var target_rotation: float = vase.get_next_slot_rotation_for_phase(current_phase)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(flower_instance, "global_position", target_global_position, 0.25)
	tween.parallel().tween_property(flower_instance, "rotation_degrees", target_rotation, 0.25)
	tween.parallel().tween_property(flower_instance, "scale", Vector2(1.05, 1.05), 0.12)
	tween.tween_property(flower_instance, "scale", Vector2.ONE, 0.13)

	await tween.finished

	vase.finalize_flower_for_phase(flower_instance, flower_id, flower_texture, is_filler, current_phase)
	is_animating = false

	refresh_phase_state()
	update_receipt_ui()
	update_submit_state()


func _on_vase_flower_removed(_flower_id: String) -> void:
	refresh_phase_state()
	update_receipt_ui()
	update_submit_state()


func _on_submit_pressed() -> void:
	if is_animating:
		return

	refresh_phase_state()

	if not is_full_bouquet_built():
		feedback_label.text = "Bouquet is not complete yet"
		return

	if is_full_bouquet_correct():
		feedback_label.text = "Correct"
		order_index += 1
		start_round()
	else:
		feedback_label.text = "Wrong"
		start_round()


func _on_clear_pressed() -> void:
	if is_animating:
		return

	vase.clear_vase()
	feedback_label.text = ""

	refresh_phase_state()
	update_receipt_ui()
	update_submit_state()


func get_flower_counts(flowers: Array[StringName]) -> Dictionary:
	var counts := {}

	for flower in flowers:
		if not counts.has(flower):
			counts[flower] = 0
		counts[flower] += 1

	return counts

func is_main_bouquet_correct() -> bool:
	var bouquet: Array[StringName] = vase.get_flowers_for_phase("main")

	if bouquet.size() != current_main_order.size():
		return false

	return get_flower_counts(bouquet) == get_flower_counts(current_main_order)

func is_filler_bouquet_correct() -> bool:
	var bouquet: Array[StringName] = vase.get_flowers_for_phase("filler")

	if bouquet.size() != current_filler_order.size():
		return false

	return get_flower_counts(bouquet) == get_flower_counts(current_filler_order)

func is_full_bouquet_correct() -> bool:
	return is_main_bouquet_correct() and is_filler_bouquet_correct()
