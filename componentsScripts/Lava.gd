extends Node2D

@export var camera: Camera2D
@export var player: CharacterBody2D

@export var fireball_scene: PackedScene
@export var warning_scene: PackedScene

@export var min_rise_speed := 100.0
@export var max_rise_speed := 1000.0

const FIREBALL_WARNING_DISTANCE := 1400.0
const WARNING_Y := 1800.0

@export var target_distance := 900.0
@export var max_distance := 3200.0

@export var scroll_speed := 200.0

@onready var sprite1: Sprite2D = $Visual/Sprite2D
@onready var sprite2: Sprite2D = $Visual/Sprite2D2
@onready var sprite3: Sprite2D = $Visual/Sprite2D3

@onready var fireballs := $Fireballs
@onready var warnings := $Warnings

var debug_timer := 0.0
var fireball_timer := 0.0

var active := false

var texture_width := 0.0
var texture_height := 0.0

var start_y := 1500.0

const TELEPORT_DISTANCE := 5000.0

const FIREBALL_INTERVAL := 2.0

const FIREBALL_START_Y := -10000.0
const FIREBALL_FULL_Y := -60000.0

const FIREBALL_MIN_CHANCE := 0.8
const FIREBALL_MAX_CHANCE := 0.9


func _ready() -> void:

	texture_width = sprite1.texture.get_width() * sprite1.scale.x
	texture_height = sprite1.texture.get_height() * sprite1.scale.y

	# side by side
	sprite1.position.x = -texture_width
	sprite2.position.x = 0
	sprite3.position.x = texture_width

	# top alignment
	sprite1.position.y = texture_height * 0.5
	sprite2.position.y = texture_height * 0.5
	sprite3.position.y = texture_height * 0.5

	global_position.y = start_y


func reset():
	for child in fireballs.get_children():
		child.queue_free()

	for child in warnings.get_children():
		child.queue_free()

	fireball_timer = 0.0

	global_position.y = start_y
	active = false


func _process(delta: float) -> void:

	if camera == null or player == null:
		return

	_fireball_logic(delta)

	debug_timer += delta

	if not active:
		return

	# dynamic lava speed
	var distance: float = global_position.y - player.global_position.y

	var t: float = inverse_lerp(
		target_distance,
		max_distance,
		distance
	)

	t = clamp(t, 0.0, 1.0)

	var current_rise_speed: float = lerp(
		min_rise_speed,
		max_rise_speed,
		t
	)

	if debug_timer >= 1.0:
		debug_timer = 0.0
		print("Lava speed: ", current_rise_speed)

	# lava rises
	global_position.y -= current_rise_speed * delta

	# fake lava flow
	sprite1.position.x += scroll_speed * delta
	sprite2.position.x += scroll_speed * delta
	sprite3.position.x += scroll_speed * delta

	# reposition around camera
	_reposition_segment(sprite1)
	_reposition_segment(sprite2)
	_reposition_segment(sprite3)


func _reposition_segment(sprite: Sprite2D) -> void:

	var cam_left: float = camera.global_position.x - get_viewport_rect().size.x * 0.5
	var cam_right: float = camera.global_position.x + get_viewport_rect().size.x * 0.5

	var sprite_left: float = sprite.global_position.x - texture_width * 0.5
	var sprite_right: float = sprite.global_position.x + texture_width * 0.5

	# completely outside right
	if sprite_left > cam_right + texture_width:

		var leftmost: float = min(
			sprite1.position.x,
			min(sprite2.position.x, sprite3.position.x)
		)

		sprite.position.x = leftmost - texture_width

	# completely outside left
	elif sprite_right < cam_left - texture_width:

		var rightmost: float = max(
			sprite1.position.x,
			max(sprite2.position.x, sprite3.position.x)
		)

		sprite.position.x = rightmost + texture_width


func _on_hitbox_body_entered(body: Node2D) -> void:

	if body != player:
		return

	player._die()


func _fireball_logic(delta: float) -> void:
	return

	fireball_timer += delta

	if fireball_timer < FIREBALL_INTERVAL:
		return

	fireball_timer = 0.0

	var py: float = player.global_position.y

	var lava_distance: float = global_position.y - py

	if lava_distance > FIREBALL_WARNING_DISTANCE:
		return

	var chance_t: float = inverse_lerp(
		FIREBALL_START_Y,
		FIREBALL_FULL_Y,
		py
	)

	chance_t = clamp(chance_t, 0.0, 1.0)

	var fireball_chance: float = lerp(
		FIREBALL_MIN_CHANCE,
		FIREBALL_MAX_CHANCE,
		chance_t
	)

	if randf() > fireball_chance:
		return

	_spawn_fireball_event()

func _spawn_fireball_event() -> void:

	print("LAUNCH FIREBALL")

	var viewport_width: float = get_viewport_rect().size.x

	# bell curve around screen center
	var offset_x: float = randfn(
		0.0,
		viewport_width * 0.18
	)

	# warning screen X
	var screen_x: float = (
		viewport_width * 0.5
		+ offset_x
	)

	# WARNING
	var warning = warning_scene.instantiate()

	warnings.add_child(warning)

	warning.start(screen_x, WARNING_Y)

	await warning.finished

	# convert warning screen position back to world
	var world_x: float = (
		(warning.global_position.x - viewport_width * 0.5)
		* camera.zoom.x
		+ camera.global_position.x
	)

	# FIREBALL
	var fireball = fireball_scene.instantiate()

	fireballs.add_child(fireball)

	fireball.global_position = Vector2(
		world_x,
		global_position.y + 100.0
	)

	fireball.launch(global_position.y + 100.0)
