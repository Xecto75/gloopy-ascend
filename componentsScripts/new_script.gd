extends CharacterBody2D

# =========================================================
# NODES
# =========================================================
@onready var sprite: AnimatedSprite2D = $Sprite2D
@onready var player_col: CollisionShape2D = $player_col
@onready var aim_preview := $AimPreview


@export var PLANET_MASK := 1 << 1  # layer 2
@export var SWEEP_EXTRA := 2.0
var drag_origin_screen: Vector2 = Vector2.ZERO


var sweep_shape: CapsuleShape2D

# =========================================================
# SIGNAL
# =========================================================
signal died
signal height_updated(height: float)


# =========================================================
# TUNING
# =========================================================
const GRAVITY := 2200.0
const LAUNCH_POWER := 6.0
const MAX_DRAG_LENGTH := 400.0
const UNSTICK_COOLDOWN := 0.12
const DRAG_RESPONSE := 1.6
const SURFACE_OFFSET := 8.0

const FAIL_SPEED := 1800.0
const FAIL_TIME := 1.5

const SPAWN_IMMUNITY_TIME := 0.6
const VISUAL_SINK := 20.0  # tweak until it looks right


# =========================================================
# STATE
# =========================================================
var dragging := false
var input_locked := true

var drag_origin_global := Vector2.ZERO
var launch_vector := Vector2.ZERO

var stuck := false
var stuck_planet: Node2D = null
var local_offset := Vector2.ZERO
var unstick_timer := 0.0
var has_launched := false

var spawn_immunity_timer := 0.0
var fall_fail_timer := 0.0
var is_landing := false

var prev_pos: Vector2

# =========================================================
# READY
# =========================================================
func _ready() -> void:
	input_locked = true
	prev_pos = global_position
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
func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			_start_drag()
		else:
			_end_drag()
	elif event is InputEventMouseMotion and dragging:
		_update_drag()

# =========================================================
# PHYSICS
# =========================================================
func _physics_process(delta: float) -> void:
	if dragging:
		aim_preview.update_preview(
			global_position,
			launch_vector,
			MAX_DRAG_LENGTH
		)


	if spawn_immunity_timer > 0.0:
		spawn_immunity_timer -= delta

	if unstick_timer > 0.0:
		unstick_timer -= delta

	if stuck:
		_follow_planet()
		_reset_fall_fail()
		return

	# Apply gravity
	velocity.y += GRAVITY * delta
	
		# --------------------------------------------------
	# SWEPT CAPSULE STICK CHECK (REPLACES RAYS)
	# --------------------------------------------------
	if unstick_timer <= 0.0:
		var motion := velocity * delta
		if motion.length_squared() > 0.0001:
			var planet := _sweep_for_planet(motion)
			if planet:
				_force_stick_to_planet(planet)
				return
				
	move_and_slide()
	var height := -global_position.y
	emit_signal("height_updated", height)


	# Air rotation
	if not dragging and spawn_immunity_timer <= 0.0 and has_launched and velocity.length_squared() > 10.0:
		_set_rotation_from_vector(velocity)


	# Falling animation
	if spawn_immunity_timer <= 0.0 and not stuck and velocity.y < 0:
		if sprite.animation != "flying":
			sprite.play("flying")

	# Fail check
	if spawn_immunity_timer <= 0.0:
		_check_fall_fail(delta)


# =========================================================
# STICKING
# =========================================================
func _force_stick_to_planet(planet: Node2D) -> void:
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
func _start_drag() -> void:
	dragging = true
	drag_origin_screen = get_viewport().get_mouse_position()
	launch_vector = Vector2.ZERO

	sprite.flip_v = false
	sprite.play("charge")
	if has_launched:
		sprite.flip_v = true

func _update_drag() -> void:
	var current_screen: Vector2 = get_viewport().get_mouse_position()

	# slingshot direction in SCREEN space (stable, no rotation feedback)
	var raw_screen: Vector2 = drag_origin_screen - current_screen
	if raw_screen.length() < 1.0:
		launch_vector = Vector2.ZERO
		return

	# convert screen delta -> world delta
	var inv_canvas := get_viewport().get_canvas_transform().affine_inverse()
	var raw_world: Vector2 = inv_canvas.basis_xform(raw_screen)

	var strength := raw_world.length()
	var scaled := pow(strength / MAX_DRAG_LENGTH, DRAG_RESPONSE) * MAX_DRAG_LENGTH
	scaled = min(scaled, MAX_DRAG_LENGTH)

	launch_vector = raw_world.normalized() * scaled

func _end_drag() -> void:
	dragging = false
	aim_preview.hide_preview()

	if stuck:
		_detach()

	velocity = launch_vector * LAUNCH_POWER
	if spawn_immunity_timer < 0.0:
		has_launched = true
		sprite.flip_v = false
		sprite.play("jump")

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
func _die() -> void:
	set_physics_process(false)
	emit_signal("died")

func _on_revive(spawn_pos: Vector2) -> void:
	global_position = spawn_pos
	prev_pos = global_position

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
	var c := cs.shape as CircleShape2D
	return c.radius

func _get_player_radius(cs: CollisionShape2D) -> float:
	var cap := cs.shape as CapsuleShape2D
	return cap.radius

func _sweep_for_planet(motion: Vector2) -> Node2D:
	var space := get_world_2d().direct_space_state

	# ----------------------------------------
	# 1) CHECK OVERLAP AT START (CRITICAL)
	# ----------------------------------------
	var start_params := PhysicsShapeQueryParameters2D.new()
	start_params.shape = sweep_shape
	start_params.transform = player_col.global_transform
	start_params.collision_mask = PLANET_MASK
	start_params.exclude = [get_rid()]
	start_params.collide_with_bodies = true
	start_params.collide_with_areas = false

	var start_hits := space.intersect_shape(start_params, 8)
	for h in start_hits:
		var c: Node2D = h["collider"]
		if c and c.is_in_group("planet"):
			return c

	# ----------------------------------------
	# 2) SWEEP ALONG MOTION
	# ----------------------------------------
	var sweep_params := PhysicsShapeQueryParameters2D.new()
	sweep_params.shape = sweep_shape
	sweep_params.transform = player_col.global_transform
	sweep_params.motion = motion
	sweep_params.collision_mask = PLANET_MASK
	sweep_params.exclude = [get_rid()]
	sweep_params.collide_with_bodies = true
	sweep_params.collide_with_areas = false
	sweep_params.margin = 0.0

	var result := space.cast_motion(sweep_params)
	var safe := result[0]
	if safe >= 1.0:
		return null

	# move to first contact
	global_position += motion * safe

	# identify collider at contact
	var contact_params := PhysicsShapeQueryParameters2D.new()
	contact_params.shape = sweep_shape
	contact_params.transform = player_col.global_transform
	contact_params.collision_mask = PLANET_MASK
	contact_params.exclude = [get_rid()]
	contact_params.collide_with_bodies = true
	contact_params.collide_with_areas = false

	var hits := space.intersect_shape(contact_params, 8)
	for h in hits:
		var c: Node2D = h["collider"]
		if c and c.is_in_group("planet"):
			return c

	return null

func _on_animation_finished() -> void:
	if is_landing:
		is_landing = false
		sprite.play("idle")
