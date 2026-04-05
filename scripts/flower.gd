extends Area2D

signal picked(flower_id)

@export var flower_id: String
@export var texture: Texture2D

@onready var sprite: Sprite2D = $Sprite2D

func _ready() -> void:
    sprite.texture = texture

func _input_event(viewport, event, shape_idx) -> void:
    if event is InputEventMouseButton and event.pressed and event.button_index ==MOUSE_BUTTON_LEFT:
        picked.emit(flower_id)
        print("emits flower_id: %s" % flower_id)