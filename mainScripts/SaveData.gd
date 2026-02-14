extends Node

const SAVE_PATH := "user://gloopy_save.cfg"

var highscore := 0
var sfx_enabled := true
var music_enabled := true
var vibrations_enabled := true

func _ready() -> void:
	load_data()

func load_data() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return

	highscore = cfg.get_value("progress", "highscore", 0)

	sfx_enabled = cfg.get_value("settings", "sfx", true)
	music_enabled = cfg.get_value("settings", "music", true)
	vibrations_enabled = cfg.get_value("settings", "vibrations", true)

func save_data() -> void:
	var cfg := ConfigFile.new()

	cfg.set_value("progress", "highscore", highscore)

	cfg.set_value("settings", "sfx", sfx_enabled)
	cfg.set_value("settings", "music", music_enabled)
	cfg.set_value("settings", "vibrations", vibrations_enabled)

	cfg.save(SAVE_PATH)
