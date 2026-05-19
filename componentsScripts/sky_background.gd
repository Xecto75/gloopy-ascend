extends CanvasLayer

@export var camera: Camera2D
@export var player: Node2D
@export var stars: Node2D

@onready var rect: ColorRect = $ColorRect

var STARS_START_Y := 0.0
var STARS_FULL_Y := 0.0

var h := SaveData.HEIGHT_PER_LEVEL

# ==================================================
# SKY COLOR
# ==================================================
var SKY_STEPS := []

const FADE_SPEED := 1.2

# ==================================================
# READY
# ==================================================

func _ready() -> void:
	randomize()

	var h := SaveData.HEIGHT_PER_LEVEL
	
	STARS_START_Y = -SaveData.HEIGHT_PER_LEVEL * 175
	STARS_FULL_Y = -SaveData.HEIGHT_PER_LEVEL * 200

	SKY_STEPS = [
		{ "y":  h * 6,    "color": Color("#7fdbe6") },
		{ "y":  0.0,      "color": Color("#6fc7db") },

		{ "y": -h * 25,   "color": Color("#5fbcd3") },
		{ "y": -h * 50,   "color": Color("#4ca8c7") },
		{ "y": -h * 75,   "color": Color("#3b8fbf") },
		{ "y": -h * 100,  "color": Color("#2f78ad") },
		{ "y": -h * 125,  "color": Color("#245f96") },
		{ "y": -h * 150,  "color": Color("#1b4a78") },

		{ "y": -h * 175,  "color": Color("#123558") },
		{ "y": -h * 200,  "color": Color.BLACK }
	]
# ==================================================
# PROCESS
# ==================================================
func _process(delta: float) -> void:
	if camera == null:
		return

	_update_sky_color(delta)
	_update_stars()

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
			
func _update_stars() -> void:
	if stars == null:
		return

	var py := player.global_position.y
	var t := inverse_lerp(STARS_START_Y, STARS_FULL_Y, py)
	t = clamp(t, 0.0, 1.0)

	stars.set_alpha(t)
