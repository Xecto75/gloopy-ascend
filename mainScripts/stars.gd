extends Node2D

const STAR_COUNT := 120

var stars := []
var alpha := 0.0


func _ready() -> void:
	randomize()
	_generate_stars()
	queue_redraw()


func _generate_stars() -> void:
	var screen_size := get_viewport_rect().size

	for i in range(STAR_COUNT):
		stars.append({
			"pos": Vector2(
				randf_range(0.0, screen_size.x),
				randf_range(0.0, screen_size.y)
			),
			"size": randf_range(0.6, 1.6)
		})


func set_alpha(a: float) -> void:
	alpha = a
	queue_redraw()


func _draw() -> void:
	for s in stars:
		draw_circle(s["pos"], s["size"], Color(1, 1, 1, alpha))
