extends Node

@export var flower_scene: PackedScene
@export var packed_bouquet_scene: PackedScene

const MAX_ORDERS: int = 2

var successful_bouquets: int = 0
var wrong_bouquets: int = 0
var available_main_flowers: Array[StringName] = []
var available_filler_flowers: Array[StringName] = []
var round_active: bool = true
var awaiting_customer: bool = false
var current_main_order: Array[StringName] = []
var current_filler_order: Array[StringName] = []
var current_phase: String = "main"
var is_animating: bool = false
var order_index: int = 0
var last_delivery_was_successful: bool = false
var delivered_bouquet: Node2D = null


@onready var vase = $'../Environment/Vase'
@onready var flower_stand_pots: Node2D = $'../Environment/FlowerStand/Pots'
@onready var flower_stand: Node2D = $'../Environment/FlowerStand'
@onready var moving_flowers = get_parent().get_node("MovingFlowers")
@onready var orderNode: Node2D = get_parent().get_node("Environment/Order")
@onready var order_label: Label = get_parent().get_node("Environment/Order/OrderLabel")
@onready var submit_button: TextureButton = get_parent().get_node("UI/SubmitButton")
@onready var clear_button: TextureButton = get_parent().get_node("UI/ClearButton")
@onready var feedback_label: Label = get_parent().get_node("UI/FeedbackLabel")
@onready var tutorial_manager: Node2D = $'../TutorialManager'
@onready var customer = $'../Environment/Customer'
@onready var highlight_react: ColorRect = $'../UI/TutorialLayer/HighlightReact'
@onready var phone = get_parent().get_node("Environment/Phone")


func _ready() -> void:
	randomize()

	flower_stand_pots.flower_selected.connect(_on_flower_selected)
	submit_button.pressed.connect(_on_submit_pressed)
	clear_button.pressed.connect(_on_clear_pressed)

	if vase.has_signal("flower_removed"):
		vase.flower_removed.connect(_on_vase_flower_removed)
	
	if vase.has_signal("single_flower_removed"):
		vase.single_flower_removed.connect(_on_tutorial_single_flower_removed)

	if tutorial_manager != null and tutorial_manager.has_signal("tutorial_finished"):
		tutorial_manager.tutorial_finished.connect(_on_tutorial_finished)

	if customer.has_signal("customer_enter_finished"):
		customer.customer_enter_finished.connect(_on_customer_enter_finished)

	if customer.has_signal("customer_leave_finished"):
		customer.customer_leave_finished.connect(_on_customer_leave_finished)

	if phone != null and phone.has_signal("phone_clicked"):
		phone.phone_clicked.connect(_on_phone_clicked)

	collect_available_flowers_from_stand()

	
	print("Phone local position:", phone.position)
	print("Phone global position:", phone.global_position)
	print("Phone parent:", phone.get_parent().name)

	order_index = 0
	successful_bouquets = 0
	wrong_bouquets = 0

	if tutorial_manager != null and tutorial_manager.start_with_tutorial:
		call_deferred("_start_phone_intro_sequence")
	else:
		call_deferred("start_customer_round")




func start_customer_round() -> void:
	print("order: ", order_index)
	round_active = false
	awaiting_customer = true

	# customer.hide_customer()
	vase.clear_vase()
	generate_current_order_by_progression()

	submit_button.disabled = true
	feedback_label.text = ""

	refresh_phase_state()
	update_receipt_ui()

	customer.show_random_customer()
	customer.play_enter()


func start_tutorial_round() -> void:
	round_active = false
	awaiting_customer = false

	orderNode.visible = false

	customer.hide_customer()
	vase.clear_vase()
	generate_current_order_by_progression()

	feedback_label.text = ""
	refresh_phase_state()
	update_receipt_ui()
	update_submit_state()


func _on_tutorial_finished() -> void:
	feedback_label.text = ""

	orderNode.visible = false
	submit_button.disabled = false
	clear_button.disabled = false

	start_customer_round()


func tutorial_blocks_pick(is_filler: bool) -> bool:
	if tutorial_manager == null or not tutorial_manager.is_tutorial_active():
		return false
	
	var step: Dictionary = tutorial_manager.get_current_step()
	if step.is_empty():
		return true
	
	var action: String = step.get("action", "")

	match action:
		"pick_main":
			return is_filler
		"complete_main_count":
			return is_filler
		"pick_filler":
			return not is_filler
		"complete_filler_count":
			return not is_filler
		"submit_bouquet":
			return false
		"remove_single_flower":
			return true
		"clear_vase":
			return true
		_:
			return true


func _on_customer_enter_finished() -> void:
	awaiting_customer = false
	round_active = true

	refresh_phase_state()
	update_receipt_ui()
	update_submit_state()
	orderNode.visible = true


func _on_customer_leave_finished() -> void:
	delivered_bouquet.queue_free()
	delivered_bouquet = null

	order_index += 1

	clear_button.disabled = false

	if order_index > MAX_ORDERS:
		end_run()
		return

	start_customer_round()


func tutorial_blocks_submit() -> bool:
	if tutorial_manager == null or not tutorial_manager.is_tutorial_active():
		return false

	var step: Dictionary = tutorial_manager.get_current_step()
	if step.is_empty():
		return false

	return step.get("action", "") != "submit_bouquet"


func tutorial_blocks_clear() -> bool:
	if tutorial_manager == null or not tutorial_manager.is_tutorial_active():
		return false

	var step: Dictionary = tutorial_manager.get_current_step()
	if step.is_empty():
		return true

	var action: String = step.get("action", "")

	if action == "submit_bouquet":
		return false

	return action != "clear_vase"


func tutorial_blocks_remove_flower() -> bool:
	if tutorial_manager == null or not tutorial_manager.is_tutorial_active():
		return false

	var step: Dictionary = tutorial_manager.get_current_step()
	if step.is_empty():
		return true

	var action: String = step.get("action", "")

	if action == "submit_bouquet":
		return false

	return action != "remove_single_flower"


func _start_phone_intro_sequence() -> void:
	customer.hide_customer()
	vase.clear_vase()
	orderNode.visible = false
	feedback_label.text = ""

	await get_tree().create_timer(2.0).timeout

	if phone != null:
		phone.start_ringing()


func _on_phone_clicked() -> void:
	start_tutorial_round()

	if tutorial_manager != null:
		tutorial_manager.start_tutorial()


func collect_available_flowers_from_stand() -> void:
	available_main_flowers.clear()
	available_filler_flowers.clear()

	for child in flower_stand_pots.get_children():
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


func generate_current_order_by_progression() -> void:
	var main_count : int
	var filler_count : int

	if order_index <= 2:
		main_count = 3
		filler_count = 2
	elif order_index <= 5:
		main_count = 5
		filler_count = 2
	else:
		main_count = 7
		filler_count = 3
	
	current_main_order = generate_order(available_main_flowers, main_count)
	current_filler_order = generate_order(available_filler_flowers, filler_count)

	var layout_size := main_count + filler_count
	print("layout set to:" + str(layout_size))
	vase.set_layout_size(layout_size)



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

	# MAIN FLOWERS
	var main_counts := get_flower_counts(current_main_order)

	for flower_id in main_counts.keys():
		text += "%s x %d\n" % [flower_id, main_counts[flower_id]]

	text += "\n---------\n"

	# FILLERS
	var filler_counts := get_flower_counts(current_filler_order)

	for flower_id in filler_counts.keys():
		text += "%s x %d\n" % [flower_id, filler_counts[flower_id]]

	order_label.text = text


func _on_flower_selected(flower_id: String, flower_texture: Texture2D, start_global_position: Vector2, is_filler: bool) -> void:
	if is_animating:
		return

	if tutorial_blocks_pick(is_filler):
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
	flower_instance.scale = Vector2(0.9, 0.9)

	var target_global_position: Vector2 = vase.get_next_slot_global_position_for_phase(current_phase)
	var target_rotation: float = vase.get_next_slot_rotation_for_phase(current_phase)

	var hover_position := start_global_position + Vector2(0, -24)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(flower_instance, "global_position", hover_position, 0.14)
	tween.parallel().tween_property(flower_instance, "scale", Vector2(1.05, 1.05), 0.14)
	tween.parallel().tween_property(flower_instance, "rotation_degrees", 0.0, 0.14)

	tween.tween_interval(0.04)

	tween.tween_property(flower_instance, "global_position", target_global_position, 0.24)
	tween.parallel().tween_property(flower_instance, "scale", Vector2.ONE, 0.24)
	tween.parallel().tween_property(flower_instance, "rotation_degrees", target_rotation, 0.24)

	await tween.finished

	vase.finalize_flower_for_phase(flower_instance, flower_id, flower_texture, is_filler, current_phase)
	is_animating = false

	refresh_phase_state()
	update_receipt_ui()
	update_submit_state()

	if tutorial_manager != null and tutorial_manager.is_tutorial_active():
		if not is_filler:
			tutorial_manager.try_progress_action("pick_main")

	if is_filler:
		tutorial_manager.try_progress_action("pick_filler")

	if get_current_main_count() >= get_required_main_count():
		tutorial_manager.try_progress_action("complete_main_count")

	if get_current_filler_count() >= get_required_filler_count():
		tutorial_manager.try_progress_action("complete_filler_count")


func _on_vase_flower_removed(_flower_id: String) -> void:
	refresh_phase_state()
	update_receipt_ui()
	update_submit_state()


func _on_submit_pressed() -> void:
	if tutorial_blocks_submit():
		return

	if is_animating:
		return

	refresh_phase_state()

	if not is_full_bouquet_built():
		feedback_label.text = "Bouquet is not complete yet"
		return

	if tutorial_manager != null and tutorial_manager.is_tutorial_active():
		if is_full_bouquet_correct():
			feedback_label.text = "Correct"
			tutorial_manager.try_progress_action("submit_bouquet")
		else:
			feedback_label.text = "Wrong"

			var step: Dictionary = tutorial_manager.get_current_step()
			if not step.is_empty():
				tutorial_manager.phone_bubble.show_message("Manager", "That bouquet is wrong. Compare it with the receipt and fix it.")

			submit_button.disabled = false
			clear_button.disabled = false
			highlight_react.visible = false

		return

	last_delivery_was_successful = is_full_bouquet_correct()

	if last_delivery_was_successful:
		successful_bouquets += 1
		feedback_label.text = "Correct"
		customer.play_happy_reaction()
	else:
		wrong_bouquets += 1
		customer.play_wrong_reaction()

	deliver_bouquet_to_customer()


func _on_clear_pressed() -> void:
	if is_animating:
		return

	if tutorial_blocks_clear():
		return

	vase.clear_vase()
	feedback_label.text = ""

	if tutorial_manager != null and tutorial_manager.is_tutorial_active():
		tutorial_manager.try_progress_action("clear_vase")

	refresh_phase_state()
	update_receipt_ui()
	update_submit_state()


func deliver_bouquet_to_customer() -> void:
	if not round_active:
		return

	round_active = false
	submit_button.disabled = true
	clear_button.disabled = true

	var bouquet_children: Array = vase.flowers_container.get_children()
	if bouquet_children.is_empty():
		orderNode.visible = false
		customer.play_leave()
		return

	var center := Vector2.ZERO
	for flower in bouquet_children:
		center += flower.global_position
	center /= bouquet_children.size()

	delivered_bouquet = packed_bouquet_scene.instantiate()
	delivered_bouquet.name = "DeliveredBouquet"
	moving_flowers.add_child(delivered_bouquet)
	delivered_bouquet.global_position = center

	var flowers_root: Node2D = delivered_bouquet.get_node("VisualRoot/FlowersRoot")

	for flower in bouquet_children:
		var global_pos: Vector2 = flower.global_position
		vase.flowers_container.remove_child(flower)
		flowers_root.add_child(flower)
		flower.global_position = global_pos

	delivered_bouquet.play_delivery()
	await delivered_bouquet.delivery_animation_finished

	var hand_target: Vector2 = customer.get_bouquet_target_global_position()

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(delivered_bouquet, "global_position", hand_target, 0.35)

	await tween.finished

	var final_global := delivered_bouquet.global_position
	moving_flowers.remove_child(delivered_bouquet)
	customer.get_node("Sprite2D/BouquetAnchor").add_child(delivered_bouquet)
	delivered_bouquet.global_position = final_global
	delivered_bouquet.position = Vector2.ZERO

	vase.clear_vase()
	orderNode.visible = false
	customer.play_leave()


func get_flower_counts(flowers: Array[StringName]) -> Dictionary:
	var counts := {}

	for flower in flowers:
		if not counts.has(flower):
			counts[flower] = 0
		counts[flower] += 1

	return counts


func is_main_bouquet_correct() -> bool:
	var bouquet: Array[StringName] = vase.get_flowers_for_phase("main")

	var order: String = "Order: "
	var bouquet_: String = "Bouquet: "

	if bouquet.size() != current_main_order.size():
		return false

	for i in current_main_order.size():
		order += current_main_order[i] + ", "

	for i in bouquet.size():
		bouquet_ += bouquet[i] + ", "
	print(order)
	print(bouquet_)
	return get_flower_counts(bouquet) == get_flower_counts(current_main_order)


func is_filler_bouquet_correct() -> bool:
	var bouquet: Array[StringName] = vase.get_flowers_for_phase("filler")

	var filler_order: String = "Order: "
	var filler_bouquet_: String = "Bouquet: "

	if bouquet.size() != current_filler_order.size():
		return false

	for i in current_filler_order.size():
		filler_order += current_filler_order[i] + ", "

	for i in bouquet.size():
		filler_bouquet_ += bouquet[i] + ", "
	
	print(filler_order)
	print(filler_bouquet_)

	return get_flower_counts(bouquet) == get_flower_counts(current_filler_order)


func is_full_bouquet_correct() -> bool:
	print("verifying bouquet")
	return is_main_bouquet_correct() and is_filler_bouquet_correct()


func _on_tutorial_single_flower_removed(_flower_id: String) -> void:
	if tutorial_manager != null and tutorial_manager.is_tutorial_active():
		tutorial_manager.try_progress_action("remove_single_flower")


func end_run() -> void:
	var summary_text := "Today was not a busy day. You saw 10 customers.\n\n"
	summary_text += "Successful bouquets: %d\n" % successful_bouquets
	summary_text += "Wrong bouquets: %d" % wrong_bouquets

	get_tree().set_meta("run_summary_text", summary_text)
	get_tree().change_scene_to_file("res://scenes/MainMenu.tscn")
