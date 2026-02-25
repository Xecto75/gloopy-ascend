extends Control

@onready var setting_overlay = $CanvasLayer/SettingPopUp
@onready var score_text = $VBoxContainer/ScoreText
@onready var game_over_text = $VBoxContainer/GameOverText
@onready var tap_label: Label = $VBoxContainer/PlayLabel
@onready var top_offset: Control = $VBoxContainer/Spacer1
@onready var bottom_offset: Control = $VBoxContainer/Spacer2

signal revive
signal overlay_close
signal open_settings


var highscore:
	get: return SaveData.highscore
	set(value):
		SaveData.highscore = value
		SaveData.save_data()



func _ready() -> void:
	var safe_area: Rect2 = DisplayServer.get_display_safe_area()
	var screen_size: Vector2i = DisplayServer.window_get_size()
	
	var top_inset: float = safe_area.position.y
	var bottom_inset: float = screen_size.y - (safe_area.position.y + safe_area.size.y)
	
	# safe_area.position.y = top notch height
	top_offset.custom_minimum_size.y += max(0.0, top_inset)
	bottom_offset.custom_minimum_size.y += max(0.0, bottom_inset)
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func show_overlay() -> void:
	visible = true

	# fade in GAME OVER
	_fade_in_label(game_over_text, 0.35)

	# fade in Tap to Play Again
	_fade_in_label(tap_label, 0.6)

	# start pulse AFTER fade
	await get_tree().create_timer(0.6).timeout
	_start_tap_pulse()


func hide_overlay() -> void:
	visible = false
	tap_label.modulate.a = 1.0
	modulate.a = 1.0
	emit_signal("overlay_close")
	
func _on_settings_button_pressed() -> void:
	emit_signal("open_settings")


	
func _on_score_updated(score: int) -> void:
	if score > highscore:
		highscore = score
		score_text.add_theme_color_override("font_color", Color("FFE666"))
		score_text.add_theme_color_override("font_shadow_color", Color("BFA200"))
		score_text.text = ("New Higscore !\n" + str(score))
		await get_tree().create_timer(0.1).timeout
		_pop_highscore_text(score_text)
	else:
		score_text.text = str(score)
		score_text.add_theme_color_override("font_color", Color("ffffff"))
		score_text.add_theme_color_override("font_shadow_color", Color("828282"))
		await get_tree().create_timer(0.1).timeout
		_pop_highscore_text(score_text)
	return
	

func _start_tap_pulse() -> void:
	while visible:
		var tween := create_tween()
		tween.tween_property(tap_label, "modulate:a", 0.35, 0.9)
		tween.tween_property(tap_label, "modulate:a", 1.0, 0.9)
		await tween.finished
		
func _fade_in_label(label: Label, duration: float = 0.35) -> void:
	label.visible = true
	label.modulate.a = 0.0

	await get_tree().process_frame

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		label,
		"modulate:a",
		1.5,
		duration
	)

func _gui_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed:
		emit_signal("revive")


func _pop_highscore_text(textLabel: Label) -> void:
	textLabel.visible = true
	textLabel.modulate = Color(1, 1, 1, 0.0)

	# wait for VBox layout
	await get_tree().process_frame

	textLabel.pivot_offset = textLabel.size * 0.5
	textLabel.scale = Vector2(0.4, 0.4)
	textLabel.modulate = Color(1, 1, 1, 1)

	var tween := create_tween()

	# BIG punch in
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(textLabel, "scale", Vector2(1.6, 1.6), 0.28)

	# settle
	tween.tween_property(textLabel, "scale", Vector2.ONE, 0.18)

	# little victory bounce
	tween.tween_property(textLabel, "scale", Vector2(1.15, 1.15), 0.12)
	tween.tween_property(textLabel, "scale", Vector2.ONE, 0.12)
