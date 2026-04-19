extends Control

@export var game_scene: PackedScene

@onready var summary_label: Label = $Feedback/SummaryLabel
@onready var summary_sprite: Sprite2D = $Feedback
@onready var start_button: TextureButton = $VBoxContainer/StartButton
@onready var exit_button: TextureButton = $VBoxContainer/ExitButton
@onready var music_slider: HSlider = $VBoxContainer/TextureRect/MusicSlider


func _ready() -> void:
	start_button.pressed.connect(_on_start_pressed)
	exit_button.pressed.connect(_on_exit_pressed)

	music_slider.value_changed.connect(_on_music_slider_changed)

	MusicManager.play_menu_music()

	summary_label.visible = false
	summary_sprite.visible = false

	if get_tree().has_meta("run_summary_text"):
		summary_label.text = str(get_tree().get_meta("run_summary_text"))
		summary_label.visible = true
		summary_sprite.visible = true
		get_tree().remove_meta("run_summary_text")


func _on_start_pressed() -> void:
	if game_scene != null:
		get_tree().change_scene_to_packed(game_scene)


func _on_exit_pressed() -> void:
	get_tree().quit()


func _on_music_slider_changed(value: float) -> void:
	_set_music_volume(value)


func _set_music_volume(value: float) -> void:
	var db = linear_to_db(max(value, 0.001))
	AudioServer.set_bus_volume_db(AudioServer.get_bus_index("Master"), db)
