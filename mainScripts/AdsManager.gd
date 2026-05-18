extends Node

signal reward_over

var interstitial_ad
var interstitial_loader
var interstitial_id: String

var rewarded_ad
var rewarded_loader
var rewarded_id: String

var death_counter := 0
var last_ad_time := 0.0
var session_start_time := 0.0

# SETTINGS
const FIRST_AD_DELAY := 60.0
const MIN_TIME_BETWEEN_ADS := 120.0
const FORCE_AD_AFTER := 180.0
const REQUIRED_DEATHS := 4

var reward_listener := OnUserEarnedRewardListener.new()

func _ready():
	reward_listener.on_user_earned_reward = _on_user_earned_reward
	session_start_time = Time.get_ticks_msec() / 1000.0
	last_ad_time = session_start_time

	interstitial_id = SaveData.interstitial_pub_id
	rewarded_id = SaveData.rewarded_pub_id

	MobileAds.initialize()

	interstitial_loader = InterstitialAdLoader.new()
	load_interstitial()

	rewarded_loader = RewardedAdLoader.new()
	load_rewarded()



# ==================================================
# INTERSTITIAL
# ==================================================

func load_interstitial():
	var request := AdRequest.new()

	var callback := InterstitialAdLoadCallback.new()

	callback.on_ad_loaded = _on_interstitial_loaded
	callback.on_ad_failed_to_load = _on_interstitial_failed

	interstitial_loader.load(
		interstitial_id,
		request,
		callback
	)


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

	if total_session_time < FIRST_AD_DELAY:
		return

	var should_show := false

	if time_since_last_ad >= FORCE_AD_AFTER:
		should_show = true

	elif (
		time_since_last_ad >= MIN_TIME_BETWEEN_ADS
		and death_counter >= REQUIRED_DEATHS
	):
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


# ==================================================
# REWARDED
# ==================================================

func load_rewarded():
	var request := AdRequest.new()

	var callback := RewardedAdLoadCallback.new()

	callback.on_ad_loaded = _on_rewarded_loaded
	callback.on_ad_failed_to_load = _on_rewarded_failed

	rewarded_loader.load(
		rewarded_id,
		request,
		callback
	)

func _on_rewarded_loaded(ad):
	print("1 - _on_rewarded_loaded")

	rewarded_ad = ad

	print("2 - rewarded_ad assigned: ", rewarded_ad)

	print("3 - setting reward callback")

	

	print("4 - reward callback assigned")

	print("5 - setting dismiss callback")

	rewarded_ad.full_screen_content_callback.on_ad_dismissed_full_screen_content = Callable(
		self,
		"_on_rewarded_dismissed"
	)

	print("6 - dismiss callback assigned")

func _on_rewarded_failed(error):
	print("Rewarded failed ❌ ", error)

	await get_tree().create_timer(5.0).timeout

	load_rewarded()

func _on_user_earned_reward(reward):
	print("13 - _on_user_earned_reward ENTERED")

	print("14 - reward object: ", reward)

	print("15 - tree paused inside reward callback: ", get_tree().paused)

	last_ad_time = Time.get_ticks_msec() / 1000.0
	death_counter = 0

	print("16 - about to emit reward_over")

	emit_signal("reward_over")

	print("17 - reward_over emitted")

func _on_rewarded_dismissed():
	print("18 - _on_rewarded_dismissed ENTERED")

	print("19 - tree paused inside dismiss callback: ", get_tree().paused)

	print("20 - rewarded_ad before null: ", rewarded_ad)

	rewarded_ad = null

	print("21 - rewarded_ad nulled")

	print("22 - reloading rewarded")

	load_rewarded()

	print("23 - load_rewarded called")

func show_rewarded_ad():
	print("7 - show_rewarded_ad called")

	if rewarded_ad:
		print("8 - rewarded_ad exists")

		print("9 - tree paused before show: ", get_tree().paused)

		print("10 - calling rewarded_ad.show()")

		rewarded_ad.show(reward_listener)

		print("11 - rewarded_ad.show() returned")
	else:
		print("12 - rewarded_ad NULL")
