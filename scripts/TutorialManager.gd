extends Node

signal tutorial_finished

@export var start_with_tutorial: bool = true

var tutorial_active: bool = false
var current_step_index: int = 0

var steps: Array[Dictionary] = []

@onready var game_manager = get_parent().get_node("GameManager")
@onready var tutorial_layer: Control = get_parent().get_node("UI/TutorialLayer")
@onready var highlight_react: ColorRect = $'../UI/TutorialLayer/HighlightReact'
@onready var pointer_arrow: Sprite2D = $'../UI/TutorialLayer/PointerArrow'
@onready var phone_bubble = get_parent().get_node("UI/PhoneBubble")


func _ready() -> void:
	_build_steps()

	tutorial_layer.visible = false
	highlight_react.visible = false
	pointer_arrow.visible = false

	phone_bubble.bubble_clicked.connect(_on_phone_bubble_clicked)

	if start_with_tutorial:
		tutorial_active = false
		tutorial_layer.visible = false


func _build_steps() -> void:
	steps = [
		{
			"id": "intro_1",
			"speaker": "Manager",
			"text": "Ah, you’re here. Good. Today is your first day.",
			"mode": "message"
		},
		{
			"id": "intro_2",
			"speaker": "Manager",
			"text": "Congratulations. You made it in.",
			"mode": "message"
		},
		{
			"id": "intro_3",
			"speaker": "Manager",
			"text": "I’ll guide you through your first bouquet. Pay attention.",
			"mode": "message"
		},
		{
			"id": "intro_4",
			"speaker": "Manager",
			"text": "This receipt shows what the customer wants.",
			"mode": "message",
			"highlight_target": "Environment/Order/OrderNote/Highlight"
		},
		{
			"id": "intro_5",
			"speaker": "Manager",
			"text": "We always start with the main flowers at the top.",
			"mode": "message"
		},
		{
			"id": "pick_main",
			"speaker": "Manager",
			"text": "Pick a main flower from the stand.",
			"mode": "wait_action",
			"action": "pick_main",
			"highlight_target": "Environment/FlowerStand/Highlight"
		},
		{
			"id": "complete_main_count",
			"speaker": "Manager",
			"text": "Now finish placing all required main flowers.",
			"mode": "wait_action",
			"action": "complete_main_count",
			"highlight_target": "Environment/Vase/Highlight"
		},
		{
			"id": "remove_one_flower",
			"speaker": "Manager",
			"text": "If you make a mistake - click a flower in the vase to remove it.",
			"mode": "wait_action",
			"action": "remove_single_flower"
		},
		{
			"id": "clear_vase_info_1",
			"speaker": "Manager",
			"text": "If things get messy, start over.",
			"mode": "message"
		},
		{
			"id": "clear_vase_info",
			"speaker": "Manager",
			"text": "Use the Clear Vase button to reset everything.",
			"mode": "wait_action",
			"action": "clear_vase",
			"highlight_target": "UI/ClearButton"
		},
		{
			"id": "rebuild_main_count",
			"speaker": "Manager",
			"text": "Now place the main flowers again.",
			"mode": "wait_action",
			"action": "complete_main_count"
		},
		{
			"id": "unlock_fillers_1",
			"speaker": "Manager",
			"text": "Good. Now we move to fillers.",
			"mode": "message"
		},
		{
			"id": "unlock_fillers_2",
			"speaker": "Manager",
			"text": "They complete the bouquet.",
			"mode": "message"
		},
		{
			"id": "pick_fillers",
			"speaker": "Manager",
			"text": "Pick a filler flower.",
			"mode": "wait_action",
			"action": "pick_filler",
			"highlight_target": "FlowerStand"
		},
		{
			"id": "complete_filler_count",
			"speaker": "Manager",
			"text": "Place all required filler flowers.",
			"mode": "wait_action",
			"action": "complete_filler_count"
		},
		{
			"id": "submit_info_1",
			"speaker": "Manager",
			"text": "Check the order carefully.",
			"mode": "message"
		},
		{
			"id": "submit_info",
			"speaker": "Manager",
			"text": "When everything is correct, press Submit.",
			"mode": "wait_action",
			"action": "submit_bouquet",
			"highlight_target": "UI/SubmitButton"
		},
		{
			"id": "done_1",
			"speaker": "Manager",
			"text": "That’s it.",
			"mode": "message"
		},
		{
			"id": "done_2",
			"speaker": "Manager",
			"text": "You’re ready to work on your own.",
			"mode": "message"
		},
		{
			"id": "done_3",
			"speaker": "Manager",
			"text": "Today will be quiet. Only ten customers.",
			"mode": "message"
		},
		{
			"id": "done_4",
			"speaker": "Manager",
			"text": "Don’t keep them waiting.",
			"mode": "message"
		}
	]


func _on_phone_bubble_clicked() -> void:
	if can_continue_message():
		next_message_step()


func start_tutorial() -> void:
	tutorial_active = true
	current_step_index = 0
	tutorial_layer.visible = true
	_show_current_step()


func finish_tutorial() -> void:
	tutorial_active = false
	tutorial_layer.visible = false
	highlight_react.visible = false
	pointer_arrow.visible = false
	phone_bubble.hide_bubble()
	tutorial_finished.emit()


func is_tutorial_active() -> bool:
	return tutorial_active


func get_current_step() -> Dictionary:
	if current_step_index < 0 or current_step_index >= steps.size():
		return {}
	return steps[current_step_index]


func can_continue_message() -> bool:
	var step := get_current_step()
	return step.has("mode") and step["mode"] == "message"


func _show_current_step() -> void:
	if current_step_index >= steps.size():
		finish_tutorial()
		return

	var step := steps[current_step_index]

	var speaker: String = step.get("speaker", "")
	var text: String = step.get("text", "")

	phone_bubble.show_message(speaker, text)

	var gm = get_tree().current_scene.get_node("GameManager")

	if step.get("action", "") == "clear_vase":
		gm.clear_button.disabled = false

	if step.get("action", "") == "submit_bouquet":
		gm.submit_button.disabled = false

	highlight_react.visible = false
	pointer_arrow.visible = false

	if step.has("highlight_target"):
		_show_highlight_for_path(step["highlight_target"])

	print(step.id)


func next_message_step() -> void:
	if not tutorial_active:
		return

	var step := get_current_step()
	if step.is_empty():
		return

	if step.get("mode", "") != "message":
		return
	
	if step.get("id", "") == "intro_3":
		var gm = get_tree().current_scene.get_node("GameManager")
		gm.orderNode.visible = true

	current_step_index += 1
	_show_current_step()


func try_progress_action(action_name: String) -> void:
	if not tutorial_active:
		return

	var step := get_current_step()
	if step.is_empty():
		return

	if step.get("mode", "") != "wait_action":
		return

	if step.get("action", "") != action_name:
		return

	current_step_index += 1
	_show_current_step()


func _show_highlight_for_path(node_path: String) -> void:
	var target = get_parent().get_node_or_null(node_path)
	if target == null:
		return

	var rect := _get_global_rect_for_node(target)
	if rect.size == Vector2.ZERO:
		return

	highlight_react.visible = true
	highlight_react.position = rect.position - Vector2(6, 6)
	highlight_react.size = rect.size + Vector2(12, 12)

	pointer_arrow.visible = true
	pointer_arrow.position = Vector2(rect.position.x + rect.size.x * 0.5 - 8.0, rect.position.y - 28.0)


func _get_global_rect_for_node(target: Node) -> Rect2:
	if target is Control:
		var control := target as Control
		return Rect2(control.global_position, control.size)

	if target is Node2D:
		var n2d := target as Node2D
		return Rect2(n2d.global_position - Vector2(32, 32), Vector2(64, 64))

	return Rect2()
