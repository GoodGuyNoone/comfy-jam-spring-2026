extends Node

@export var flower_scene: PackedScene
@export var available_flowers: Array[StringName] = [
	"rose",
	"tulip",
	"lily",
	"iris",
	"gerbera",
	"cala lily",
	"snapdragon",
	"daisy",
	"peony",
	"ruscus",
]

@onready var flower_stand: Node2D = $'../FlowerStand'
@onready var vase = get_parent().get_node("Vase")
@onready var moving_flowers = $'../MovingFlowers'
@onready var test_label: Label = $'../TestLabel'
@onready var feedback_label: Label = $'../FeedbackLabel'
@onready var submit_button: Button = $'../UI/SubmitButton'
@onready var clear_vase_button: Button = $'../UI/ClearVaseButton'


var is_animating: bool = false
var current_order: Array[StringName] = []
# var target_rotation: float = vase.get_next_slot_rotation()


func _ready() -> void:
	randomize()
	flower_stand.flower_selected.connect(_on_flower_selected)
	submit_button.pressed.connect(_on_submit_pressed)
	clear_vase_button.pressed.connect(_on_clear_vase_pressed)
	call_deferred("start_round")


func start_round():
	current_order = generate_order(5)
	print("New order:", current_order)
	vase.clear_vase()
	update_receipt_ui()
	# feedback_label.text = ""


func _on_flower_selected(flower_id: String, flower_texture: Texture2D, start_global_position: Vector2) -> void:
	var target_rotation: float = vase.get_next_slot_rotation()
	if is_animating:
		return
	
	if vase.is_full():
		return
	
	is_animating = true

	var flower_instance = flower_scene.instantiate()
	moving_flowers.add_child(flower_instance)
	flower_instance.setup(flower_id, flower_texture, false, true)
	flower_instance.global_position = start_global_position

	var target_global_position: Vector2 = vase.get_next_slot_global_position()

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_QUAD)
	tween.set_ease(Tween.EASE_OUT)

	tween.parallel().tween_property(flower_instance, "global_position", target_global_position, 0.25)
	tween.parallel().tween_property(flower_instance, "rotation", deg_to_rad(randf_range(-4.0, 4.0)), 0.25)
	tween.parallel().tween_property(flower_instance, "scale", Vector2(1.05, 1.05), 0.12)
	tween.parallel().tween_property(flower_instance, "rotation_degrees", target_rotation, 0.25)
	tween.tween_property(flower_instance, "scale", Vector2.ONE, 0.13)

	await tween.finished

	vase.finalize_flower(flower_instance, flower_id, flower_texture)
	is_animating = false


func _on_submit_pressed() -> void:
	if is_animating:
		return

	print("Order: ", current_order)
	print("Bouquet: ", vase.get_flowers())
	print("Valid: ", is_bouquet_correct())
	
	if is_bouquet_correct():
		feedback_label.text = "Correct"
		start_round()
	else:
		feedback_label.text = "Wrong"
		start_round()


func _on_clear_vase_pressed() -> void:
	if is_animating:
		return
	
	vase.clear_vase()


func generate_order(count: int = 5) -> Array[StringName]:
	var order: Array[StringName] = []

	for i in range(count):
		var random_index = randi() % available_flowers.size()
		order.append(available_flowers[random_index])
	
	return order


func update_receipt_ui():
	var text := "Order: "

	for flower in current_order:
		text += flower + " "
	
	test_label.text = text


func get_flower_counts(flowers: Array[StringName]) -> Dictionary:
	var counts := {}

	for flower in flowers:
		if not counts.has(flower):
			counts[flower] = 0
		counts[flower] += 1
	
	return counts


func is_bouquet_correct() -> bool:
	var bouquet: Array[StringName] = vase.get_flowers()

	if bouquet.size() != current_order.size():
		return false
	
	return get_flower_counts(bouquet) == get_flower_counts(current_order)
