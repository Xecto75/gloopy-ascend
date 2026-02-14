extends Node2D

@export var camera: Camera2D
@onready var pause_button: Button = $UI/PauseButton
var target_overlay_alpha := 0.0
var freeze_dark_overlay := false

@onready var home_slime: Sprite2D = $World/HomeSlime

@onready var bgm: AudioStreamPlayer = $BGM
@onready var player: Node = $World/Player

@onready var settings_popup = $UI/SettingPopUp

@onready var pause_popup = $UI/PausePopUp
@onready var home_overlay = $UI/HomeOverlay
@onready var game_over_overlay = $UI/GameOverOverlay
@onready var dark_overlay = $UI/DarkOverlay


@onready var score_label: Label = $UI/ScoreLabel
@onready var bonus_label: Label = $UI/BonusLabel


var skip_next_overlay_click := false

var max_height := 0.0
var score := 0
const SCORE_SCALE := 0.1
signal score_update(score: int)
const SPAWN_POS := Vector2(590, 1380)

func _ready() -> void:
	
	bgm.volume_db = -20
	bgm.play()

	create_tween().tween_property(
		bgm,
		"volume_db",
		-15.0,
		1.5
	)
	
	process_mode = Node.PROCESS_MODE_ALWAYS
	pause_button.process_mode = Node.PROCESS_MODE_ALWAYS

	player.died.connect(_on_player_died)
	player.height_updated.connect(_on_player_height_updated)
	player.score_bonus.connect(_bonus_score_updated)

	pause_popup.open_settings.connect(_open_settings)

	# Whenever ANY UI closes, recompute pause + overlay visibility.
	pause_popup.overlay_close.connect(_refresh_ui)
	settings_popup.overlay_close.connect(_refresh_ui)
	game_over_overlay.overlay_close.connect(_refresh_ui)
	home_overlay.overlay_close.connect(_refresh_ui)
	
	home_overlay.start_game.connect(_on_home_start_game)
	score_update.connect(game_over_overlay._on_score_updated)

	dark_overlay.visible = false
	dark_overlay.mouse_filter = Control.MOUSE_FILTER_STOP
	dark_overlay.gui_input.connect(_on_overlay_gui_input)
	$World/WorldGenerator.active = false
	_show_home()

func _on_home_start_game() -> void:
	home_slime.visible = true

	var tween := create_tween()

	tween.tween_property(home_overlay, "modulate:a", 0.0, 0.35)
	tween.parallel().tween_property(home_slime, "modulate:a", 0.0, 0.35)

	await tween.finished

	home_overlay.visible = false
	home_overlay.modulate.a = 1.0

	home_slime.visible = false
	home_slime.modulate.a = 1.0

	$World/WorldGenerator.start_generation()
	_refresh_ui()


func _process(_delta: float) -> void:
	if home_slime and home_overlay.visible:
		home_slime.global_position = camera.global_position + camera.offset

	_update_pause_button_visibility()

# --------------------------
# SCORE
# --------------------------
func _on_player_height_updated(height: float) -> void:
	if height + 1600 <= max_height:
		return
	max_height = height + 1600
	score = int((max_height-210) * SCORE_SCALE)
	score_label.text = str(score)
	
func _on_player_died() -> void:
	_vibrate(120)
	score_update.emit(score)
	score = 0
	max_height = 0
	score_label.text = ""
	_show_game_over()

func _on_revive_player() -> void:
	var gen = $World/WorldGenerator
	
	gen.reset()
	gen.start_generation()

	player._on_revive(SPAWN_POS)

	_hide_all_ui()
	_refresh_ui()


# --------------------------
# UI OPENERS
# --------------------------
func _on_pause_button_pressed() -> void:
	call_deferred("_show_pause")

func _open_settings() -> void:
	_show_settings()

func _show_pause() -> void:
	_hide_all_ui()
	pause_popup.show_popup()
	_refresh_ui()
	_fade_in_overlay()

func _show_settings() -> void:
	pause_popup.hide_popup()
	game_over_overlay.hide_overlay()

	settings_popup.show_popup()
	_refresh_ui()
	_fade_in_overlay()



func _show_home() -> void:
	print("score hide")
	score_label.visible = false
	_hide_all_ui()
	home_overlay.show_overlay()
	_refresh_ui()
	_fade_in_overlay()

func _show_game_over() -> void:
	score_label.visible = false
	_hide_all_ui()
	game_over_overlay.show_overlay()
	_refresh_ui()
	_fade_in_overlay()

# --------------------------
# UI CLOSE / STACK RULES
# --------------------------
func _hide_all_ui() -> void:
	pause_popup.hide_popup()
	settings_popup.hide_popup()
	game_over_overlay.hide_overlay()
	home_overlay.hide_overlay()

func _refresh_ui() -> void:
	var gameplay_ui : bool = pause_popup.visible \
		or settings_popup.visible \
		or game_over_overlay.visible \
		or home_overlay.visible

	dark_overlay.visible = pause_popup.visible \
		or settings_popup.visible \
		or game_over_overlay.visible

	if game_over_overlay.visible:
		target_overlay_alpha = 0.70
	elif pause_popup.visible or settings_popup.visible:
		target_overlay_alpha = 0.4
	else:
		target_overlay_alpha = 0.0

	get_tree().paused = pause_popup.visible \
		or settings_popup.visible \
		or game_over_overlay.visible

	_update_score_visibility()
func _update_score_visibility() -> void:
	var should_show : bool = not home_overlay.visible \
		and not game_over_overlay.visible

	if should_show and not score_label.visible:
		score_label.visible = true
		score_label.modulate.a = 0.0

		var tween := create_tween()
		tween.tween_property(score_label, "modulate:a", 1.0, 0.25)

	elif not should_show and score_label.visible:
		var tween := create_tween()
		tween.tween_property(score_label, "modulate:a", 0.0, 0.2)
		await tween.finished
		score_label.visible = false

func _close_topmost_ui() -> void:
	if settings_popup.visible:
		settings_popup.hide_popup()
		return

	if pause_popup.visible:
		pause_popup.hide_popup()
		return

	if game_over_overlay.visible:
		game_over_overlay.hide_overlay()
		_on_revive_player()
		return


func _on_overlay_gui_input(event: InputEvent) -> void:
	if not event is InputEventMouseButton:
		return
	if skip_next_overlay_click:
		skip_next_overlay_click = false
		return

	if event is InputEventMouseButton and not event.pressed:
		_close_topmost_ui()
		_refresh_ui()


# --------------------------
# MISC
# --------------------------
func _update_pause_button_visibility() -> void:
	var gameplay_active : bool = not home_overlay.visible \
		and not game_over_overlay.visible

	pause_button.visible = gameplay_active and not get_tree().paused


func _on_pause_button_button_up() -> void:
	call_deferred("_show_pause")
	
func _bonus_score_updated(bonus_type: String) -> void:
	match bonus_type:
		"big_jump":
			score += 50
			_show_bonus_popup("BIG MOVE!\n+50")
			_vibrate(30)
		"perfect_jump":
			score += 100
			_show_bonus_popup("PERFECT JUMP!\n +100")
			_vibrate(30)
			await get_tree().create_timer(0.08).timeout
			_vibrate(30)

	score_label.text = str(score)
	_animate_score_punch()

func _animate_score_punch() -> void:
	score_label.scale = Vector2.ONE

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	tween.tween_property(
		score_label,
		"scale",
		Vector2(1.40, 1.40),
		0.2
	)
	tween.tween_property(
		score_label,
		"scale",
		Vector2.ONE,
		0.15
	)
	
func _show_bonus_popup(text: String) -> void:
	bonus_label.text = text
	bonus_label.visible = true
	bonus_label.modulate.a = 1.0
	bonus_label.scale = Vector2(0.6, 0.6)

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_BACK)
	tween.set_ease(Tween.EASE_OUT)

	# pop in
	tween.tween_property(
		bonus_label,
		"scale",
		Vector2.ONE,
		0.2
	)

	# slight hold
	tween.tween_interval(0.35)

	# fade out
	tween.tween_property(
		bonus_label,
		"modulate:a",
		0.0,
		0.4
	)

	tween.finished.connect(func():
		bonus_label.visible = false
	)
	
	
func _fade_in_dark_overlay() -> void:
	dark_overlay.visible = true
	dark_overlay.modulate.a = 0.0
	

	var tween := create_tween()
	tween.set_trans(Tween.TRANS_SINE)
	tween.set_ease(Tween.EASE_OUT)
	tween.tween_property(
		dark_overlay,
		"modulate:a",
		1.0,
		0.45
	)

func _vibrate(ms: int) -> void:
	if not OS.has_feature("mobile"):
		return

	if not settings_popup.vibrations:
		return

	Input.vibrate_handheld(ms)
	

func _fade_in_overlay() -> void:
	dark_overlay.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(
		dark_overlay,
		"modulate:a",
		target_overlay_alpha,
		0.25
	)
