extends Node

var interstitial_ad
var interstitial_loader
var interstitial_id : String = SaveData.interstitial_pub_id

var death_counter := 0
var last_ad_time := 0.0
var session_start_time := 0.0

const MAX_DEATHS := 4
const MIN_SESSION_TIME := 60.0
const MAX_TIME_WITHOUT_AD := 240.0

func _ready():
	session_start_time = Time.get_ticks_msec() / 1000.0
	last_ad_time = session_start_time

	MobileAds.initialize()

	interstitial_loader = InterstitialAdLoader.new()
	load_interstitial()

func load_interstitial():
	var request := AdRequest.new()

	var callback := InterstitialAdLoadCallback.new()
	callback.on_ad_loaded = _on_interstitial_loaded
	callback.on_ad_failed_to_load = _on_interstitial_failed

	interstitial_loader.load(interstitial_id, request, callback)

func _on_interstitial_loaded(ad):
	print("Interstitial loaded ✅")
	interstitial_ad = ad

	# Connect dismissal callback
	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = _on_interstitial_dismissed

func _on_interstitial_failed(error):
	print("Interstitial failed ❌ ", error)

func _on_interstitial_dismissed():
	print("Interstitial dismissed → reloading")
	load_interstitial()

func on_player_death():
	death_counter += 1

	var now := Time.get_ticks_msec() / 1000.0
	var total_session_time := now - session_start_time
	var time_since_last_ad := now - last_ad_time

	if total_session_time < MIN_SESSION_TIME:
		return

	if death_counter >= MAX_DEATHS or time_since_last_ad >= MAX_TIME_WITHOUT_AD:
		show_interstitial()
		death_counter = 0
		last_ad_time = now

func show_interstitial():
	if interstitial_ad:
		print("Showing interstitial")
		interstitial_ad.show()
	else:
		print("Interstitial not ready")
