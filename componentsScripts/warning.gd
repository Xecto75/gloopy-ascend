# warning.gd
extends Control

@export var blink_count := 3
@export var blink_time := 0.12

signal finished

func _ready() -> void:
	visible = false
	
func start(screen_x: float, screen_y: float) -> void:

	visible = true

	global_position = Vector2(screen_x, screen_y)

	modulate.a = 0.0

	for i in blink_count:

		modulate.a = 1.0
		await get_tree().create_timer(blink_time).timeout

		modulate.a = 0.0
		await get_tree().create_timer(blink_time).timeout

	finished.emit()
	queue_free()
