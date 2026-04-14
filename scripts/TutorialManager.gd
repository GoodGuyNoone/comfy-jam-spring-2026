extends Node

signal tutorial_finished

@export var start_with_tutorial: bool = true

var tutorial_active: bool = false
var current_step_index: int = 0

var steps: Array[Dictionary] = []

@onready var game_manager = get_parent().get_node("GameManager")
@onready var tutorial_layer: Control = get_parent().get_node("UI/TutorialLayer")
@onready var message_panel: Panel = $'../UI/TutorialLayer/MessagePanel'
@onready var speaker_label: Label = $'../UI/TutorialLayer/MessagePanel/SpeakerLabel'
@onready var message_label: Label = $'../UI/TutorialLayer/MessagePanel/MessageLabel'
@onready var next_arrow: Label = $'../UI/TutorialLayer/MessagePanel/NextArrow'
@onready var highlight_react: ColorRect = $'../UI/TutorialLayer/HighlightReact'
@onready var pointer_arrow: Sprite2D = $'../UI/TutorialLayer/PointerArrow'


func _ready() -> void:
	_build_steps()

	tutorial_layer.visible = false
	highlight_react.visible = false
	pointer_arrow.visible = false

	message_panel.gui_input.connect(_on_bubble_gui_input)
	next_arrow.gui_input.connect(_on_next_arrow_gui_input)

	if start_with_tutorial:
		call_deferred("start_tutorial")

func _build_steps() -> void:
	steps = [
		{
			"id": "intro_1",
			"speaker": "Manager",
			"text": "Welcome. I will guide you through your first bouquet.",
			"mode": "message"
		},
		{
			"id": "intro_2",
			"speaker": "Manager",
			"text": "This receipt shows what the customer wants. First place the main flowers.",
			"mode": "message",
			"highlight_target": "UI/Order"
		},
		{
			"id": "pick_main",
			"speaker": "Manager",
			"text": "Pick a main flower from the stand.",
			"mode": "wait_action",
			"action": "pick_main",
			"highlight_target": "FlowerStand"
		},
		{
			"id": "complete_main_count",
			"speaker": "Manager",
			"text": "Good. Place the required main flowers into the vase.",
			"mode": "wait_action",
			"action": "complete_main_count",
			"highlight_target": "Vase"
		},
		{
			"id": "remove_one_flower",
			"speaker": "Manager",
			"text": "If you make a mistake, click a flower in the vase to remove it.",
			"mode": "wait_action",
			"action": "remove_single_flower",
			"highlight_target": "Vase"
		},
		{
			"id": "clear_vase_info",
			"speaker": "Manager",
			"text": "You can also reset the whole bouquet with the Clear Vase button.",
			"mode": "wait_action",
			"action": "clear_vase",
			"highlight_target": "UI/ClearButton"
		},
		{
			"id": "rebuild_main_count",
			"speaker": "Manager",
			"text": "Now place the main flowers again.",
			"mode": "wait_action",
			"action": "complete_main_count",
			"highlight_target": "Vase"
		},
		{
			"id": "pick_fillers",
			"speaker": "Manager",
			"text": "Now fillers are unlocked. Pick a filler flower.",
			"mode": "wait_action",
			"action": "pick_filler",
			"highlight_target": "FlowerStand"
		},
		{
			"id": "complete_filler_count",
			"speaker": "Manager",
			"text": "Place the required filler flowers.",
			"mode": "wait_action",
			"action": "complete_filler_count",
			"highlight_target": "Vase"
		},
		{
			"id": "submit_info",
			"speaker": "Manager",
			"text": "When the bouquet is complete, press submit.",
			"mode": "wait_action",
			"action": "submit_bouquet",
			"highlight_target": "UI/SubmitButton"
		},
		{
			"id": "done",
			"speaker": "Manager",
			"text": "Good. You are ready to work on your own now.",
			"mode": "message"
		}
	]


func _on_bubble_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if can_continue_message():
			next_message_step()


func _on_next_arrow_gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
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

	speaker_label.text = step.get("speaker", "")
	message_label.text = step.get("text", "")

	highlight_react.visible = false
	pointer_arrow.visible = false

	if step.has("highlight_target"):
		_show_highlight_for_path(step["highlight_target"])

func next_message_step() -> void:
	if not tutorial_active:
		return

	var step := get_current_step()
	if step.is_empty():
		return

	if step.get("mode", "") != "message":
		return

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
