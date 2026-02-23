extends CharacterBody2D

# =========================================================
# NODES
# =========================================================
@onready var fail_sfx: AudioStreamPlayer2D = $fail
@onready var jump_sfx: AudioStreamPlayer2D = $jumping
@onready var land_sfx :Array[AudioStreamPlayer2D]= [
	$landing1,
	$landing2,
	$landing3
]
@export var pause_button: Control


var dead:= false
@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var player_col: CollisionShape2D = $player_col
@onready var aim_preview := $AimPreview

@export var PLANET_MASK := 1 << 1  # layer 2
@export var SWEEP_EXTRA := 2.0

var drag_origin_screen: Vector2 = Vector2.ZERO
var sweep_shape: CapsuleShape2D

var rock_stuck := false

# =========================================================
# SIGNALS
# =========================================================
signal died
signal height_updated(height: float)
signal score_bonus(bonus_type: String)

# =========================================================
# TUNING
# =========================================================
const GRAVITY := 2200.0
const LAUNCH_POWER := 6.5
const MAX_DRAG_LENGTH := 400.0
const UNSTICK_COOLDOWN := 0.12
const DRAG_RESPONSE := 1.6
const SURFACE_OFFSET := 8.0
var stuck_rock: Node2D = null
var rock_local_offset := Vector2.ZERO

const FAIL_SPEED := 1800.0
const FAIL_TIME := 1.5

const SPAWN_IMMUNITY_TIME := 0.6
const VISUAL_SINK := 20.0


# --- AIR TIME / LANDING IMPACT ---
var air_time := 0.0
var was_airborne := false
var base_camera_offset := Vector2.ZERO

# --- JUMP METRICS ---
var jump_start_y := 0.0
var last_landing_y := 0.0
var jump_evaluated := false


@export var AIRTIME_SHAKE_THRESHOLD := 0.6
@export var MAX_SHAKE_STRENGTH := 12.0
@export var SHAKE_DURATION := 0.18

@onready var camera: Camera2D = $Sprite2D/Camera2D

# =========================================================
# STATE
# =========================================================
var dragging := false
var input_locked := true

var launch_vector := Vector2.ZERO

var stuck := false
var stuck_planet: Node2D = null
var local_offset := Vector2.ZERO
var unstick_timer := 0.0
var has_launched := false

var spawn_immunity_timer := 0.0
var fall_fail_timer := 0.0
var is_landing := false

# --- ROCK CONTACT STATE (NEW) ---
var touching_rock := false
var was_touching_rock := false

# =========================================================
# READY
# =========================================================
func _ready() -> void:
	base_camera_offset = camera.offset
	input_locked = true
	spawn_immunity_timer = SPAWN_IMMUNITY_TIME
	rotation = 0.0

	var cap := player_col.shape as CapsuleShape2D
	sweep_shape = CapsuleShape2D.new()
	sweep_shape.radius = cap.radius + SWEEP_EXTRA
	sweep_shape.height = cap.height

	sprite.animation_finished.connect(_on_animation_finished)
	sprite.flip_v = true
	sprite.play("idle")

# =========================================================
# INPUT
# =========================================================

func _input(event: InputEvent) -> void:
	if dead:
		return

	# -------------------------
	# PRESS: start drag (unless press is on pause button)
	# -------------------------
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and event.pressed:
		var pos :Vector2= event.position

		# Block drag start if press begins on Pause button
		if pause_button and pause_button.visible and pause_button.get_global_rect().has_point(pos):
			return

		_start_drag()
		return

	# -------------------------
	# MOVE: update drag while holding
	# -------------------------
	if event is InputEventMouseMotion:
		if dragging:
			_update_drag()
		return

	if event is InputEventScreenDrag:
		if dragging:
			_update_drag()
		return

	# -------------------------
	# RELEASE: end drag (jump)
	# -------------------------
	if (event is InputEventMouseButton or event is InputEventScreenTouch) and not event.pressed:
		if dragging:
			_update_drag() # ensure final vector is updated at release moment
			_end_drag()
		return

# =========================================================
# PHYSICS
# =========================================================
func _physics_process(delta: float) -> void:

	if dead:
		return
	# --------------------------
	# AIM PREVIEW
	# --------------------------
	if dragging:
		aim_preview.update_preview(
			global_position,
			launch_vector,
			MAX_DRAG_LENGTH
		)

	# --------------------------
	# TIMERS
	# --------------------------
	if spawn_immunity_timer > 0.0:
		spawn_immunity_timer -= delta

	if unstick_timer > 0.0:
		unstick_timer -= delta

	# --------------------------
	# AIR TIME TRACKING
	# --------------------------
	var airborne := not stuck and not rock_stuck
	
	if airborne:
		air_time += delta
	else:
		air_time = 0.0
	# --------------------------
	# PLANET FOLLOW
	# --------------------------
	if stuck:
		_follow_planet()
		_reset_fall_fail()
		return

	# --------------------------
	# GRAVITY
	# --------------------------
	if not rock_stuck:
		velocity.y += GRAVITY * delta
	if rock_stuck and stuck_rock:
		global_position = stuck_rock.to_global(rock_local_offset)
		return

	# --------------------------
	# PLANET SWEEP (ONLY PLANETS)
	# --------------------------
	if not rock_stuck and unstick_timer <= 0.0:
		var motion := velocity * delta
		if motion.length_squared() > 0.0001:
			var planet := _sweep_for_planet(motion)
			if planet:
				_force_stick_to_planet(planet)
				return

	# --------------------------
	# MOVE
	# --------------------------
	move_and_slide()

	# --------------------------
	# ROCK CONTACT (LOCK ONCE)
	# --------------------------
	if not rock_stuck:
		for i in range(get_slide_collision_count()):
			var col := get_slide_collision(i).get_collider()
			if col and (col.collision_layer & (1 << 2)) != 0:
				_on_rock_entered()
				break

	# --------------------------
	# HEIGHT
	# --------------------------
	var height := -global_position.y
	emit_signal("height_updated", height)

	# --------------------------
	# AIR ROTATION
	# --------------------------
	if not dragging \
	and spawn_immunity_timer <= 0.0 \
	and has_launched \
	and not rock_stuck \
	and velocity.length_squared() > 10.0:
		_set_rotation_from_vector(velocity)

	# --------------------------
	# FALLING ANIMATION
	# --------------------------
	if spawn_immunity_timer <= 0.0 \
	and not stuck \
	and not rock_stuck \
	and velocity.y < 0:
		if sprite.animation != "flying":
			sprite.play("flying")

	# --------------------------
	# FAIL CHECK
	# --------------------------
	if spawn_immunity_timer <= 0.0 and not rock_stuck:
		_check_fall_fail(delta)

# =========================================================
# ROCK EVENTS (NEW & ISOLATED)
# =========================================================
func _on_rock_entered() -> void:

	rock_stuck = true
	stuck_rock = get_slide_collision(get_slide_collision_count()-1).get_collider()

	velocity = Vector2.ZERO
	rotation = 0.0

	rock_local_offset = stuck_rock.to_local(global_position)

	is_landing = true
	sprite.flip_v = true
	sprite.play("landing")
	_play_random_landing_sfx()

func _on_rock_exited() -> void:
	is_landing = false

# =========================================================
# PLANET STICKING
# =========================================================
func _force_stick_to_planet(planet: Node2D) -> void:
	_evaluate_jump_bonus()
	# --- IMPACT SHAKE ---
	if air_time >= AIRTIME_SHAKE_THRESHOLD:
		var t :float= clamp(
			(air_time - AIRTIME_SHAKE_THRESHOLD) / 1.5,
			0.0,
			1.0
		)
		_shake_camera(lerp(4.0, MAX_SHAKE_STRENGTH, t))

	air_time = 0.0

	stuck = true
	velocity = Vector2.ZERO
	stuck_planet = planet

	var planet_col := planet.get_node("CollisionShape2D") as CollisionShape2D
	var planet_r := _get_planet_radius(planet_col)
	var player_r := _get_player_radius(player_col)

	var dir := (global_position - planet.global_position).normalized()
	if dir.length_squared() < 0.0001:
		dir = Vector2.UP

	global_position = planet.global_position + dir * (planet_r + player_r + SURFACE_OFFSET)
	local_offset = planet.to_local(global_position)

	_update_orientation_on_planet()
	is_landing = true
	sprite.play("landing")
	_play_random_landing_sfx()

	if planet.has_method("on_player_stick"):
		planet.on_player_stick()

func _follow_planet() -> void:
	if stuck_planet == null:
		stuck = false
		return
	global_position = stuck_planet.to_global(local_offset)
	_update_orientation_on_planet()

func _detach() -> void:
	if stuck_planet and stuck_planet.has_method("on_player_unstick"):
		stuck_planet.on_player_unstick()

	sprite.position = Vector2.ZERO
	stuck = false
	stuck_planet = null
	unstick_timer = UNSTICK_COOLDOWN

# =========================================================
# AIM / LAUNCH
# =========================================================

func _press_started_on_ui(pos: Vector2) -> bool:
	for c in get_tree().get_nodes_in_group("ui_block_click"):
		if c is Control and c.visible:
			# global rect in canvas coords
			if c.get_global_rect().has_point(pos):
				return true
	return false
	
func _start_drag() -> void:
	if not stuck and not rock_stuck:
		return

	dragging = true
	drag_origin_screen = get_viewport().get_mouse_position()
	launch_vector = Vector2.ZERO

	is_landing = false  # <-- IMPORTANT

	if rock_stuck:
		sprite.flip_v = false
	else:
		sprite.flip_v = true

	sprite.play("charge")

func _update_drag() -> void:
	
	var current_screen := get_viewport().get_mouse_position()
	var raw_screen := drag_origin_screen - current_screen
	if raw_screen.length() < 1.0:
		launch_vector = Vector2.ZERO
		return

	var inv_canvas := get_viewport().get_canvas_transform().affine_inverse()
	var raw_world := inv_canvas.basis_xform(raw_screen)

	var strength := raw_world.length()
	var scaled := pow(strength / MAX_DRAG_LENGTH, DRAG_RESPONSE) * MAX_DRAG_LENGTH
	launch_vector = raw_world.normalized() * min(scaled, MAX_DRAG_LENGTH)

func _end_drag() -> void:
	if not dragging:
		return
		
	dragging = false
	aim_preview.hide_preview()
	#dont fly
	if not stuck and not rock_stuck:
		return

	if rock_stuck:
		rock_stuck = false
		stuck_rock = null

	if stuck:
		_detach()

	velocity = launch_vector * LAUNCH_POWER

	if spawn_immunity_timer <= 0.0:
		has_launched = true
		sprite.flip_v = false
		sprite.play("jump")
		jump_sfx.play()
		
		jump_start_y = global_position.y
		jump_evaluated = false

	is_landing = false

# =========================================================
# ORIENTATION / FAIL
# =========================================================
func _update_orientation_on_planet() -> void:
	var n := (stuck_planet.global_position - global_position).normalized()
	_set_rotation_from_vector(n)
	sprite.position = Vector2(0.0, -VISUAL_SINK)

func _set_rotation_from_vector(v: Vector2) -> void:
	if v.length_squared() > 0.0:
		rotation = v.angle() + PI / 2.0

func _check_fall_fail(delta: float) -> void:
	if stuck or velocity.y <= 0.0 or velocity.length() < FAIL_SPEED:
		fall_fail_timer = 0.0
		return

	var facing_down := Vector2.from_angle(rotation - PI / 2.0).dot(Vector2.DOWN) > 0.6
	if not facing_down:
		fall_fail_timer = 0.0
		return

	fall_fail_timer += delta
	if fall_fail_timer >= FAIL_TIME:
		_die()

func _reset_fall_fail() -> void:
	fall_fail_timer = 0.0

# =========================================================
# DEATH / REVIVE
# =========================================================
func _die():
	if dead:
		return
	dead = true
	print("PLAYER DIED emitted from id:", get_instance_id())
	emit_signal("died")

	if dead:
		return
	dead = true
	velocity = Vector2.ZERO
	fail_sfx.play()
	air_time = 0.0
	jump_evaluated = false
	emit_signal("died")




func _on_revive(spawn_pos: Vector2) -> void:
	dead = false
	air_time = 0.0
	global_position = spawn_pos
	velocity = Vector2.ZERO
	set_physics_process(true)

	stuck = false
	stuck_planet = null
	local_offset = Vector2.ZERO
	unstick_timer = 0.0
	fall_fail_timer = 0.0
	has_launched = false
	spawn_immunity_timer = SPAWN_IMMUNITY_TIME

	dragging = false
	launch_vector = Vector2.ZERO
	aim_preview.hide_preview()

	rotation = 0.0
	sprite.play("idle")
	sprite.flip_v = true

# =========================================================
# UTIL
# =========================================================
func _get_planet_radius(cs: CollisionShape2D) -> float:
	return (cs.shape as CircleShape2D).radius

func _get_player_radius(cs: CollisionShape2D) -> float:
	return (cs.shape as CapsuleShape2D).radius

func _sweep_for_planet(motion: Vector2) -> Node2D:
	var space := get_world_2d().direct_space_state

	var start_params := PhysicsShapeQueryParameters2D.new()
	start_params.shape = sweep_shape
	start_params.transform = player_col.global_transform
	start_params.collision_mask = PLANET_MASK
	start_params.exclude = [get_rid()]

	for h in space.intersect_shape(start_params, 8):
		var c :Node2D= h["collider"]
		if c and c.is_in_group("planet"):
			return c

	var sweep_params := PhysicsShapeQueryParameters2D.new()
	sweep_params.shape = sweep_shape
	sweep_params.transform = player_col.global_transform
	sweep_params.motion = motion
	sweep_params.collision_mask = PLANET_MASK
	sweep_params.exclude = [get_rid()]

	var result := space.cast_motion(sweep_params)
	if result[0] >= 1.0:
		return null

	global_position += motion * result[0]

	var contact_params := PhysicsShapeQueryParameters2D.new()
	contact_params.shape = sweep_shape
	contact_params.transform = player_col.global_transform
	contact_params.collision_mask = PLANET_MASK
	contact_params.exclude = [get_rid()]

	for h in space.intersect_shape(contact_params, 8):
		var c :Node2D= h["collider"]
		if c and c.is_in_group("planet"):
			return c

	return null

func _on_animation_finished() -> void:
	if is_landing:
		is_landing = false
		sprite.play("idle")
		
func _play_random_landing_sfx() -> void:
	if land_sfx.is_empty():
		return

	var i := randi() % land_sfx.size()
	land_sfx[i].play()
	
func _shake_camera(strength: float) -> void:
	var timer := 0.0

	while timer < SHAKE_DURATION:
		var t := timer / SHAKE_DURATION
		var fade := 1.0 - t

		var shake := Vector2(
			randf_range(-1.0, 1.0),
			0
		) * strength * fade

		camera.offset = base_camera_offset + shake

		await get_tree().process_frame
		timer += get_process_delta_time()

	camera.offset = base_camera_offset

func _evaluate_jump_bonus() -> void:
	if jump_evaluated:
		return

	jump_evaluated = true

	var landing_y := global_position.y
	var delta_y := jump_start_y - landing_y  # positive = upward progress
	#print("ΔY:", delta_y)

	# --- thresholds (tune later) ---
	const BIG_MOVE_Y := 1150.0
	const PERFECT_MOVE_Y := 1400.0


	# PERFECT JUMP — precision
	if delta_y >= PERFECT_MOVE_Y:
		print("PERFECT JUMP! +100")
		emit_signal("score_bonus", "perfect_jump")
		# add_score(100)
		# show_floating_text("PERFECT!")
	
	# BIG MOVE — commitment
	elif delta_y >= BIG_MOVE_Y:
		print("BIG MOVE! +50")
		emit_signal("score_bonus", "big_jump")
		# add_score(50)
		# show_floating_text("BIG MOVE!")

	

	last_landing_y = landing_y
