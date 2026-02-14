extends Control

@onready var setting_overlay = $CanvasLayer/SettingPopUp
@onready var score_text = $VBoxContainer/ScoreText
@onready var game_over_text = $VBoxContainer/GameOverText

signal revive
signal overlay_close

var highscore:
	get: return SaveData.highscore
	set(value):
		SaveData.highscore = value
		SaveData.save_data()



func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false


func show_overlay() -> void:
	visible = true
	_pop_label_text(game_over_text)


func hide_overlay() -> void:
	visible = false
	emit_signal("overlay_close")
	

func _on_settings_button_pressed() -> void:
	setting_overlay.show_popup()
	
func _on_score_updated(score: int) -> void:
	if score > highscore:
		highscore = score
		score_text.text = ("New Higscore !\n" + str(score))
		await get_tree().create_timer(0.1).timeout
		_pop_highscore_text(score_text)
	else:
		score_text.text = str(score)
		await get_tree().create_timer(0.1).timeout
		_pop_label_text(score_text)
	return
	
func _pop_label_text(textLabel: Label) -> void:
	# ensure it participates in layout
	textLabel.visible = true

	# hide visually (NOT via visible)
	textLabel.modulate.a = 0.0

	# wait for VBoxContainer layout
	await get_tree().process_frame

	# now we can safely animate
	textLabel.pivot_offset = textLabel.size * 0.5
	textLabel.scale = Vector2(0.6, 0.6)
	textLabel.modulate.a = 1.0

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		textLabel,
		"scale",
		Vector2.ONE,
		0.2
	)


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
