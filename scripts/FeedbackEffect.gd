extends Node2D

signal effect_finished

@export var success_sound: AudioStream
@export var wrong_sound: AudioStream

@onready var animated_sprite: AnimatedSprite2D = $AnimatedSprite2D
@onready var audio_player: AudioStreamPlayer2D = $AudioStreamPlayer2D


func _ready() -> void:
	visible = false
	animated_sprite.visible = false
	animated_sprite.animation_finished.connect(_on_animation_finished)


func play_success() -> void:
	visible = true
	animated_sprite.visible = true
	animated_sprite.play("success")

	if success_sound != null:
		audio_player.stream = success_sound
		audio_player.play()


func play_wrong() -> void:
	visible = true
	animated_sprite.visible = true
	animated_sprite.play("wrong")

	if wrong_sound != null:
		audio_player.stream = wrong_sound
		audio_player.play()


func reset_effect() -> void:
	animated_sprite.stop()
	animated_sprite.visible = false
	visible = false


func _on_animation_finished() -> void:
	reset_effect()
	effect_finished.emit()