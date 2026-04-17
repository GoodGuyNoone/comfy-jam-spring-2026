extends Control

@export var game_scene: PackedScene

@onready var summary_label: Label = $VBoxContainer/SummaryLabel
@onready var start_button: Button = $VBoxContainer/StartButton
@onready var exit_button: Button = $VBoxContainer/ExitButton


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	summary_label.visible = false

	if get_tree().has_meta("run_summary_text"):
		summary_label.text = str(get_tree().get_meta("run_summary_text"))
		summary_label.visible = true
		get_tree().remove_meta("run_summary_text")


func _on_start_pressed() -> void:
	if game_scene != null:
		get_tree().change_scene_to_packed(game_scene)


func _on_exit_pressed() -> void:
	get_tree().quit()