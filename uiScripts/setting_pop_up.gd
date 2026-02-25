extends Control

@onready var panel: Control = $PopUpTemplate/OutsidePanel
@onready var blocker: ColorRect= $BlockerOverlay
@export var home_overlay: Control

signal overlay_close

var vibrations: bool = true

func _ready() -> void:
	process_mode = Node.PROCESS_MODE_ALWAYS
	visible = false

	# Make blocker catch clicks outside the panel
	blocker.mouse_filter = Control.MOUSE_FILTER_STOP
	blocker.gui_input.connect(_on_blocker_input)

	# Make sure panel blocks clicks so they don't close the popup
	panel.mouse_filter = Control.MOUSE_FILTER_STOP

	# (keep your SaveData + AudioServer init)
	vibrations = SaveData.vibrations_enabled
	AudioServer.set_bus_mute(AudioServer.get_bus_index("SFX"), not SaveData.sfx_enabled)
	AudioServer.set_bus_mute(AudioServer.get_bus_index("BGM"), not SaveData.music_enabled)



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
	panel.pivot_offset = panel.size / 2

	var tw := create_tween()
	tw.tween_property(panel, "scale", Vector2.ZERO, 0.15) \
		.set_trans(Tween.TRANS_BACK) \
		.set_ease(Tween.EASE_IN)

	await tw.finished
	home_overlay.on_settings_closed()

	panel.visible = false
	visible = false
	panel.scale = Vector2.ONE

	emit_signal("overlay_close")


func _on_sound_button_toggled(on: bool) -> void:
	SaveData.sfx_enabled = on
	SaveData.save_data()

	var bus := AudioServer.get_bus_index("SFX")
	AudioServer.set_bus_mute(bus, not on)

func _on_music_button_toggled(on: bool) -> void:
	SaveData.music_enabled = on
	SaveData.save_data()

	var bus := AudioServer.get_bus_index("BGM")
	AudioServer.set_bus_mute(bus, not on)

	
func _on_blocker_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and not event.pressed:
		if not panel.get_global_rect().has_point(event.position):
			hide_popup()

func _on_vibration_button_toggled(on: bool) -> void:
	vibrations = on
	SaveData.vibrations_enabled = on
	SaveData.save_data()


func _on_privacy_policy_link_meta_clicked(meta: Variant) -> void:
	OS.shell_open("https://your-privacy-policy-url.com")
