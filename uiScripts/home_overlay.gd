extends Control

@onready var setting_overlay = $CanvasLayer/SettingPopUp
@onready var highscore_text = $highscoreLabel

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


func hide_overlay() -> void:
	visible = false
	modulate.a = 1.0
	emit_signal("overlay_close")


func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed:
		emit_signal("start_game")

func _on_settings_button_pressed() -> void:
	setting_overlay.show_popup()
