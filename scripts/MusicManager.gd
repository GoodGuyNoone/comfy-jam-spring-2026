extends Node

@export var menu_music: AudioStream
@export var game_music_tracks: Array[AudioStream] = []

@export var fade_time: float = 1.2

@onready var player_a: AudioStreamPlayer = $PlayerA
@onready var player_b: AudioStreamPlayer = $PlayerB


var active_player: AudioStreamPlayer
var inactive_player: AudioStreamPlayer
var current_bus_volume_db: float = 0.0


func _ready() -> void:
	active_player = player_a
	inactive_player = player_b

	player_a.bus = "Master"
	player_b.bus = "Master"


func play_menu_music() -> void:
	print("play_menu_music called, menu_music:", menu_music)
	if menu_music == null:
		return
	_play_stream(menu_music)


func play_random_game_music() -> void:
	if game_music_tracks.is_empty():
		return

	var next_track := game_music_tracks[randi() % game_music_tracks.size()]
	_play_stream(next_track)


func _play_stream(stream: AudioStream) -> void:
	if active_player.stream == stream and active_player.playing:
		return

	inactive_player.stop()
	inactive_player.stream = stream
	inactive_player.volume_db = -40.0
	inactive_player.play()

	var tween := create_tween()
	tween.set_parallel(true)
	tween.tween_property(active_player, "volume_db", -40.0, fade_time)
	tween.tween_property(inactive_player, "volume_db", 0.0, fade_time)

	await tween.finished

	active_player.stop()

	var temp = active_player
	active_player = inactive_player
	inactive_player = temp
