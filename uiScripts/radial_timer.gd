extends Node2D

@export var duration: float = 4.0
@export var radius: float = 85.0
@export var thickness: float = 12.0
@export var color: Color = Color("4cd22d")

var elapsed: float = 0.0
var running: bool = false

signal revive_timeout

func start():
	elapsed = 0.0
	running = true
	queue_redraw()

func _process(delta):
	if running:
		elapsed += delta
		if elapsed >= duration:
			elapsed = duration
			running = false
			#close popup
			print("send signal")
			emit_signal("revive_timeout")
		queue_redraw()

func _draw():
	var progress = 1.0 - (elapsed / duration)
	var angle = progress * TAU
	var start_angle = PI/2
	var end_angle = start_angle + angle
	draw_arc(Vector2.ZERO, radius, start_angle, end_angle, 100, color, thickness, true)
