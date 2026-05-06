extends Node

var interstitial_ad
var interstitial_loader
var interstitial_id : String

var death_counter := 0
var last_ad_time := 0.0
var session_start_time := 0.0

# SETTINGS
const FIRST_AD_DELAY := 60.0
const MIN_TIME_BETWEEN_ADS := 120.0
const FORCE_AD_AFTER := 180.0
const REQUIRED_DEATHS := 4

func _ready():
	session_start_time = Time.get_ticks_msec() / 1000.0
	last_ad_time = session_start_time

	interstitial_id = SaveData.interstitial_pub_id

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

	ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = _on_interstitial_dismissed

func _on_interstitial_failed(error):
	print("Interstitial failed ❌ ", error)

	await get_tree().create_timer(5.0).timeout
	load_interstitial()

func _on_interstitial_dismissed():
	print("Interstitial dismissed → reloading")

	interstitial_ad = null
	load_interstitial()

func on_player_death():
	death_counter += 1

	var now := Time.get_ticks_msec() / 1000.0

	var total_session_time := now - session_start_time
	var time_since_last_ad := now - last_ad_time

	print("Deaths:", death_counter)
	print("Session:", total_session_time)
	print("Since last ad:", time_since_last_ad)

	# Never show ad during first minute
	if total_session_time < FIRST_AD_DELAY:
		return

	var should_show := false

	# Force ad after 3 minutes no matter what
	if time_since_last_ad >= FORCE_AD_AFTER:
		should_show = true

	# Otherwise require BOTH:
	# - at least 2 minutes since last ad
	# - at least 4 deaths
	elif time_since_last_ad >= MIN_TIME_BETWEEN_ADS and death_counter >= REQUIRED_DEATHS:
		should_show = true

	if should_show:
		show_interstitial()

		death_counter = 0
		last_ad_time = now

func show_interstitial():
	if interstitial_ad:
		print("Showing interstitial")
		interstitial_ad.show()
	else:
		print("Interstitial not ready")
