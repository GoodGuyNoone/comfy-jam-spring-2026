extends Node2D

signal customer_enter_finished
signal customer_leave_finished

@export var customer_textures: Array[Texture2D]

@onready var sprite: Sprite2D = $Sprite2D
@onready var animation_player: AnimationPlayer = $AnimationPlayer
@onready var bouquet_anchor: Marker2D = $Sprite2D/BouquetAnchor


func _ready():
	visible = false
	animation_player.animation_finished.connect(_on_animation_finished)


func show_random_customer() -> void:
	visible = true
	sprite.texture = customer_textures[randi() % customer_textures.size()]


func play_enter() -> void:
	animation_player.play("enter_customer")


func play_idle() -> void:
	animation_player.play("idle")


func play_leave() -> void:
	animation_player.play("leave_customer")


func hide_customer() -> void:
	visible = false


func get_bouquet_target_global_position() -> Vector2:
	print(bouquet_anchor.global_position)
	return bouquet_anchor.global_position


func _on_animation_finished(anim_name: String) -> void:
	if anim_name == "enter_customer":
		play_idle()
		customer_enter_finished.emit()
	elif anim_name == "leave_customer":
		hide_customer()
		customer_leave_finished.emit()
