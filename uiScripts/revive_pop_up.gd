extends Control

@onready var panel: Control = $PopUpTemplate/OutsidePanel

signal revive_denied
signal revive_pressed

@onready var radial_timer = $PopUpTemplate/OutsidePanel/InsidePanel/PopUpContent/RadialTimer


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS

	radial_timer.revive_timeout.connect(_on_revive_timeout)
	AdsManager.reward_over.connect(_on_rewarded_completed)


func show_overlay() -> void:
	visible = true

	panel.scale = Vector2(0.7, 0.7)

	var tw := create_tween()

	tw.tween_property(
		panel,
		"scale",
		Vector2.ONE,
		0.22
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	radial_timer.start()


func hide_popup() -> void:
	if not visible:
		return

	panel.pivot_offset = panel.size / 2

	var tw := create_tween()

	tw.tween_property(
		panel,
		"scale",
		Vector2.ZERO,
		0.15
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_IN)

	await tw.finished

	panel.scale = Vector2.ONE
	visible = false


func _on_revive_button_pressed() -> void:
	radial_timer.running = false
	_on_rewarded_completed()
	AdsManager.show_rewarded_ad()


func _on_rewarded_completed() -> void:
	await hide_popup()
	print("REWARDS SIGNAL RECEIVED")

	emit_signal("revive_pressed", true)


func _on_revive_timeout() -> void:
	await hide_popup()

	emit_signal("revive_denied")
