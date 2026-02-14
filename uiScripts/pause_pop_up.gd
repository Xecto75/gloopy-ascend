extends Control

@onready var panel: Control = $PopUpTemplate/OutsidePanel

signal open_settings
signal overlay_close

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

func show_popup() -> void:
	visible = true
	panel.visible = true

	panel.pivot_offset = panel.size / 2
	panel.scale = Vector2.ZERO
	create_tween() \
		.tween_property(panel, "scale", Vector2.ONE, 0.25) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_OUT)

func hide_popup() -> void:
	if not visible:
		return

	panel.pivot_offset = panel.size / 2
	var tw := create_tween()
	tw.tween_property(panel, "scale", Vector2.ZERO, 0.15) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_IN)

	await tw.finished

	panel.visible = false
	panel.scale = Vector2.ONE
	visible = false

	emit_signal("overlay_close")

func _on_resume_button_pressed() -> void:
	hide_popup()

func _on_settings_button_pressed() -> void:
	hide_popup()
	emit_signal("open_settings")
