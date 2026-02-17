extends Control

@onready var setting_overlay = $CanvasLayer/SettingPopUp
@onready var highscore_text = $highscoreLabel
@onready var tap_label: Label = $PlayLabel

signal open_settings 
signal overlay_close
signal start_game   # NEW

func _ready() -> void:
	highscore_text.text = "Highscore: " + str(SaveData.highscore)
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false
	
	# IMPORTANT: Home must receive clicks
	mouse_filter = Control.MOUSE_FILTER_STOP


func show_overlay() -> void:
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

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed:
		emit_signal("start_game")

func _on_settings_button_pressed() -> void:
	emit_signal("open_settings")
