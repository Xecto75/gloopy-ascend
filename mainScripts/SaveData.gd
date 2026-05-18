extends Node


# Detect platform
var is_android := OS.get_name() == "Android"
var is_ios := OS.get_name() == "iOS"

# IDs
var game_id : String
var interstitial_pub_id : String
var rewarded_pub_id : String
		
const SAVE_PATH := "user://gloopy_save.cfg"

var highscore := 1
var revive_used := false
var sfx_enabled := true
var music_enabled := true
var vibrations_enabled := true

var HEIGHT_PER_LEVEL: float = 5000
#DIFFICULTY SETTINGS
const MIN_PLANET_SIZE := 80.0
const MIN_PLANET_SIZE_START := 150.0
const MAX_PLANET_SIZE_START := 250.0

const MIN_PLANET_POPULATION := 0.1

const MIN_LAVA_SPEED := 100.0
const MAX_LAVA_SPEED := 1000.0

const MIN_PLANET_DISTANCE_START := 300.0
const MIN_PLANET_DISTANCE_END := 750.0
const MAX_PLANET_DISTANCE_START := 800.0
const MAX_PLANET_DISTANCE_END := 1000.0

const MIN_FIREBALL_FREQUENCY := 0.05

#DIFFICULTY PARAMETERS
var PLANET_SIZE_MIN : float
var PLANET_SIZE_MAX : float

var PLANET_POPULATION : float

var LAVA_SPEED : float

var PLANET_DISTANCE_MIN : float
var PLANET_DISTANCE_MAX : float

var FIREBALL_FREQUENCY : float


func update_difficulty(level: int) -> void:
	if level > 200:
		return
	match level%10:
		1, 6:
			PLANET_SIZE_MIN = max(
				((MIN_PLANET_SIZE-MIN_PLANET_SIZE_START)/200)*level 
				+ MIN_PLANET_SIZE_START,
				MIN_PLANET_SIZE
			)
			PLANET_SIZE_MAX = max(
				((MIN_PLANET_SIZE-MAX_PLANET_SIZE_START)/200)*level 
				+ MAX_PLANET_SIZE_START,
				MIN_PLANET_SIZE
			)
		2, 7:
			PLANET_DISTANCE_MIN = min(
				((MIN_PLANET_DISTANCE_END-MIN_PLANET_DISTANCE_START)/200)*level 
				+ MIN_PLANET_DISTANCE_START,
				MIN_PLANET_DISTANCE_END
			)
			PLANET_DISTANCE_MAX = min(
				((MAX_PLANET_DISTANCE_END-MAX_PLANET_DISTANCE_START)/200)*level 
				+ MAX_PLANET_DISTANCE_START,
				MAX_PLANET_DISTANCE_END
			)
		3, 8:
			PLANET_POPULATION = max(
				1-((1-MIN_PLANET_POPULATION)/200)*level,
				MIN_PLANET_POPULATION
			)
		4, 9:
			FIREBALL_FREQUENCY = min(
				0.05+((1-MIN_FIREBALL_FREQUENCY)/200)*level,
				1
			)
		0, 5:
			LAVA_SPEED = min(
				((MAX_LAVA_SPEED-MIN_LAVA_SPEED)/200)*level 
				+ MIN_LAVA_SPEED,
				MAX_LAVA_SPEED
			)
		_:
			return
	#print("========================================")
	#print("LEVEL: ", level)
	#print("PLANET_SIZE_MIN: ", PLANET_SIZE_MIN)
	#print("PLANET_SIZE_MAX: ", PLANET_SIZE_MAX)
	#print("PLANET_POPULATION: ", PLANET_POPULATION)
	#print("LAVA_SPEED: ", LAVA_SPEED)
	#print("PLANET_DISTANCE_MIN: ", PLANET_DISTANCE_MIN)
	#print("PLANET_DISTANCE_MAX: ", PLANET_DISTANCE_MAX)
	#print("FIREBALL_FREQUENCY: ", FIREBALL_FREQUENCY)
	#print("========================================")
	return


func points_to_level(points: int) -> int:
	return floor(points / HEIGHT_PER_LEVEL) + 1

func reset_difficulty() -> void:
	PLANET_SIZE_MIN = MIN_PLANET_SIZE_START
	PLANET_SIZE_MAX = MAX_PLANET_SIZE_START
	PLANET_POPULATION = 1
	LAVA_SPEED = MIN_LAVA_SPEED
	PLANET_DISTANCE_MIN = MIN_PLANET_DISTANCE_START
	PLANET_DISTANCE_MAX = MAX_PLANET_DISTANCE_START
	FIREBALL_FREQUENCY = MIN_FIREBALL_FREQUENCY


func _ready():
	reset_difficulty()
	
	if is_android:
		game_id = "ca-app-pub-1699112300277782~2519884646"
		interstitial_pub_id = "ca-app-pub-1699112300277782/9257371744"
		rewarded_pub_id = "ca-app-pub-1699112300277782/3108785770"
		
		#Test ids
		#interstitial_pub_id = "ca-app-pub-3940256099942544/103317371"
		#rewarded_pub_id = "ca-app-pub-3940256099942544/5224354917"
	elif is_ios:
		game_id = "ca-app-pub-1699112300277782~7397970521"
		interstitial_pub_id = "ca-app-pub-1699112300277782/4842795658"
		rewarded_pub_id = "ca-app-pub-1699112300277782/3402253646"
		
		#test ids
		#rewarded_pub_id = "ca-app-pub-3940256099942544/5224354917"
		#interstitial_pub_id = "ca-app-pub-3940256099942544/4411468910"
		
	print(interstitial_pub_id)
	load_data()




func load_data() -> void:
	var cfg := ConfigFile.new()
	var err := cfg.load(SAVE_PATH)
	if err != OK:
		return

	highscore = cfg.get_value("progress", "highscore", 1)

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
