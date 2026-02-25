extends Control

@onready var setting_overlay = $VBox/CanvasLayer/SettingPopUp
@onready var highscore_text = $VBox/HBox/highscoreLabel
@onready var tap_label: Label = $VBox/PlayLabel
@export var camera: Camera2D
@onready var settings_button: Control = $VBox/HBox/Button
@onready var top_offset: Control = $VBox/Spacer1
@onready var bottom_offset: Control = $VBox/Spacer4

var settings_active := false
signal open_settings 
signal overlay_close
signal start_game   # NEW

func _ready() -> void:
	var safe_area: Rect2 = DisplayServer.get_display_safe_area()
	var screen_size: Vector2i = DisplayServer.window_get_size()
	
	var top_inset: float = safe_area.position.y
	var bottom_inset: float = screen_size.y - (safe_area.position.y + safe_area.size.y)
	
	# safe_area.position.y = top notch height
	top_offset.custom_minimum_size.y += max(0.0, top_inset)
	bottom_offset.custom_minimum_size.y += max(0.0, bottom_inset)
		
	highscore_text.text = "Highscore: " + str(SaveData.highscore)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	# IMPORTANT: Home must receive clicks
	mouse_filter = Control.MOUSE_FILTER_STOP


func show_overlay() -> void:
	mouse_filter = Control.MOUSE_FILTER_STOP 
	highscore_text.text = "Highscore: " + str(SaveData.highscore)
	visible = true

	tap_label.modulate.a = 1.0
	_start_tap_pulse()



func hide_overlay() -> void:
	visible = false
	tap_label.modulate.a = 1.0
	modulate.a = 1.0
	emit_signal("overlay_close")


func _start_tap_pulse() -> void:
	while visible:
		var tween := create_tween()
		tween.tween_property(tap_label, "modulate:a", 0.35, 0.9)
		tween.tween_property(tap_label, "modulate:a", 1.0, 0.9)
		await tween.finished

func _input(event: InputEvent) -> void:
	if not visible:
		return
		
	if settings_active:
		return

	if event is InputEventMouseButton and event.pressed:
		if settings_button.get_global_rect().has_point(event.position):
			return

		start_game.emit()



func _on_settings_button_pressed() -> void:
	settings_active = true
	print("button pressed")
	emit_signal("open_settings")
	
func on_settings_closed() -> void:
	settings_active = false
