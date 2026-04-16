extends Node2D

signal delivery_animation_finished
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var back: Sprite2D = $VisualRoot/Back
@onready var flowers_root: Node2D = $VisualRoot/FlowersRoot
@onready var front: Sprite2D = $VisualRoot/Front


func _ready() -> void:
	animation_player.animation_finished.connect(_on_animation_finished)


func play_delivery() -> void:
	animation_player.play("deliver_to_customer")


func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "deliver_to_customer":
		delivery_animation_finished.emit()
