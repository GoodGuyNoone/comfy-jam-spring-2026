extends Sprite2D

var speed := 80.0
var drift := 12.0
var rotation_speed := 0.4
var direction := Vector2.LEFT

func _process(delta: float) -> void:
	global_position += (direction * speed + Vector2(0, drift)) * delta
	rotation += rotation_speed * delta
	
	if global_position.x < -100 or global_position.y > 900:
		queue_free()