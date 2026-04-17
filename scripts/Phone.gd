extends Node2D

signal phone_clicked

@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D

var is_ringing: bool = false


func _ready() -> void:
	print("PHONE _ready local:", position, " global:", global_position)
	await get_tree().process_frame
	print("PHONE after 1 frame local:", position, " global:", global_position)
	stop_ringing()


func start_ringing() -> void:
	is_ringing = true
	visible = true
	animation_player.play("phone_ring")
	audio_player.play()


func stop_ringing() -> void:
	is_ringing = false
	animation_player.stop()
	audio_player.stop()


func _on_click_area_input_event(viewport, event, _shape_idx) -> void:
	if not is_ringing:
		return

	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		viewport.set_input_as_handled()
		stop_ringing()
		phone_clicked.emit()
		print("Phone clicked")
