extends Node


# Detect platform
var is_android := OS.get_name() == "Android"
var is_ios := OS.get_name() == "iOS"

# IDs
var game_id := ""
var interstitial_pub_id := ""
		
const SAVE_PATH := "user://gloopy_save.cfg"

var highscore := 0
var sfx_enabled := true
var music_enabled := true
var vibrations_enabled := true

func _ready():
	if is_android:
		game_id = "ca-app-pub-1699112300277782~2519884646"
		interstitial_pub_id = "ca-app-pub-1699112300277782/9257371744"
	elif is_ios:
		game_id = "ca-app-pub-1699112300277782~7397970521"
		interstitial_pub_id = "ca-app-pub-1699112300277782/4842795658"
	print(interstitial_pub_id)
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
