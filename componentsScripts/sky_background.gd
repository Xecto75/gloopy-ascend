extends CanvasLayer

@export var camera: Camera2D
@export var player: Node2D
@export var stars: Node2D

@onready var rect: ColorRect = $ColorRect

# ==================================================
# SKY COLOR
# ==================================================
const SKY_STEPS := [
	{ "y":  3000.0,  "color": Color("#7fdbe6") },
	{ "y":  0.0,     "color": Color("#6fc7db") },
	{ "y": -6000.0,  "color": Color("#5fbcd3") },
	{ "y": -15000.0, "color": Color("#3b8fbf") },
	{ "y": -27000.0, "color": Color("#2a6f9e") },
	{ "y": -42000.0, "color": Color("#1f4e79") },
	{ "y": -60000.0, "color": Color("#0b1d2a") },
	{ "y": -81000.0, "color": Color.BLACK }
]

const FADE_SPEED := 1.2

# ==================================================
# READY
# ==================================================
func _ready() -> void:
	
	randomize()

# ==================================================
# PROCESS
# ==================================================
func _process(delta: float) -> void:
	if camera == null:
		return

	_update_sky_color(delta)

# ==================================================
# SKY COLOR
# ==================================================
func _update_sky_color(delta: float) -> void:
	var py := player.global_position.y
	var target := _get_color_for_height(py)
	rect.color = rect.color.lerp(target, delta * FADE_SPEED)

func _get_color_for_height(y: float) -> Color:
	for i in range(SKY_STEPS.size() - 1):
		var a = SKY_STEPS[i]
		var b = SKY_STEPS[i + 1]
		if y <= a.y and y > b.y:
			var t := inverse_lerp(a.y, b.y, y)
			return a.color.lerp(b.color, t)
	return SKY_STEPS.back().color

# ==================================================
# CAMERA RECT (WORLD SPACE)
# ==================================================
func _get_camera_world_rect() -> Rect2:
	var size := get_viewport().get_visible_rect().size
	var center := camera.get_screen_center_position()
	return Rect2(center - size * 0.5, size)

# ==================================================
# RANDOM POINT OUTSIDE CAMERA RECT
# ==================================================
func _random_point_outside_rect(rect: Rect2, margin: float) -> Vector2:
	var side := randi() % 4

	match side:
		0: # top
			return Vector2(
				randf_range(rect.position.x - margin, rect.position.x + rect.size.x + margin),
				rect.position.y - margin
			)
		1: # bottom
			return Vector2(
				randf_range(rect.position.x - margin, rect.position.x + rect.size.x + margin),
				rect.position.y + rect.size.y + margin
			)
		2: # left
			return Vector2(
				rect.position.x - margin,
				randf_range(rect.position.y - margin, rect.position.y + rect.size.y + margin)
			)
		_: # right
			return Vector2(
				rect.position.x + rect.size.x + margin,
				randf_range(rect.position.y - margin, rect.position.y + rect.size.y + margin)
			)
