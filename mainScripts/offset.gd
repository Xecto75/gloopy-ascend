extends CanvasLayer

func _ready():
	_apply_safe_area()

func _apply_safe_area():
	var safe: Rect2i = DisplayServer.get_display_safe_area()
	offset.y = safe.position.y
