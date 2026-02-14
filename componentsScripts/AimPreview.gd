extends Node2D

const DOT_RADIUS := 8
const DOT_COUNT := 10
const DOT_SPACING := 26.0
const DOT_MAX_SCALE := 1.0
const DOT_MIN_SCALE := 0.25

var dots: Array[Sprite2D] = []


func _ready() -> void:
	var img := Image.create(DOT_RADIUS * 2, DOT_RADIUS * 2, false, Image.FORMAT_RGBA8)
	img.fill(Color.TRANSPARENT)

	var center := Vector2(DOT_RADIUS, DOT_RADIUS)

	for y in range(img.get_height()):
		for x in range(img.get_width()):
			if Vector2(x, y).distance_to(center) <= DOT_RADIUS:
				img.set_pixel(x, y, Color.WHITE)

	var tex := ImageTexture.create_from_image(img)

	for i in range(DOT_COUNT):
		var d := Sprite2D.new()
		d.texture = tex
		d.centered = true
		d.visible = false
		add_child(d)
		dots.append(d)


func hide_preview() -> void:
	for d in dots:
		d.visible = false


func update_preview(origin: Vector2, launch_vector: Vector2, max_length: float) -> void:
	if launch_vector == Vector2.ZERO:
		hide_preview()
		return

	var dir := launch_vector.normalized()
	var strength: float = clamp(launch_vector.length() / max_length, 0.0, 1.0)

	for i in range(dots.size()):
		var dot := dots[i]
		dot.visible = true

		var t := float(i) / float(dots.size() - 1)

		dot.global_position = origin + dir * DOT_SPACING * (i + 1)

		var scale: float = lerp(DOT_MAX_SCALE, DOT_MIN_SCALE, t) * strength
		dot.scale = Vector2.ONE * scale
