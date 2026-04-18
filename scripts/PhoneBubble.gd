extends Control

signal bubble_clicked
signal bubble_animation_finished

@onready var bubble_sprite = $BubbleSprite
@onready var speaker_label: Label = $SpeakerLabel
@onready var message_label: Label = $MessageLabel
@onready var next_arrow = $NextArrow
@onready var animation_player: AnimationPlayer = $AnimationPlayer


func _ready() -> void:
	visible = false
	speaker_label.visible = false
	message_label.visible = false
	next_arrow.visible = false
	animation_player.animation_finished.connect(_on_animation_finished)


func show_message(speaker: String, text: String) -> void:
	speaker_label.text = speaker
	message_label.text = text

	visible = true
	speaker_label.visible = false
	message_label.visible = false
	next_arrow.visible = false

	animation_player.play("show_bubble")
	await bubble_animation_finished


func hide_bubble() -> void:
	animation_player.stop()
	speaker_label.visible = false
	message_label.visible = false
	next_arrow.visible = false
	visible = false


func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "show_bubble":
		speaker_label.visible = true
		message_label.visible = true
		next_arrow.visible = true
		animation_player.play("idle")
		bubble_animation_finished.emit()


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		bubble_clicked.emit()
