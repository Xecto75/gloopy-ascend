extends Node2D

@export var planet_scene: PackedScene
@export var player: Node2D
var active := false


const START_POSITIONS := [
	Vector2(300, 600),
	Vector2(800, 400),
	Vector2(900, 800)
]


const MIN_RADIUS: float = 100.0
const MAX_RADIUS: float = 200.0

const SIDE_SPAWN_START_Y := 3000.0
const SIDE_SPAWN_END_Y := -81000.0

const SIDE_SPAWN_SCALE_START := 1.0
const SIDE_SPAWN_SCALE_END := 0.05


const GAP_START_Y := 3000.0
const GAP_END_Y := -81000.0

const MIN_GAP_START := 200.0
const MAX_GAP_START := 800.0

const MIN_GAP_END := 400.0
const MAX_GAP_END := 1000.0


const GENERATION_DISTANCE: float = 2000.0
const DESPAWN_DISTANCE: float = 3000.0
const SAFETY_MARGIN: float = 200.0

const MAX_ANCHOR_ATTEMPTS: int = 10
const MAX_SIDE_ATTEMPTS: int = 5

var anchor_planets: Array[Node2D] = []
var side_planets: Array[Node2D] = []

var highest_anchor_y: float = 0.0


func _ready() -> void:
	randomize()

func start_generation() -> void:
	if active:
		return

	active = true
	_create_initial_anchor()

func reset() -> void:
	active = false

	# Delete all planets
	for planet in anchor_planets:
		if is_instance_valid(planet):
			planet.queue_free()

	for planet in side_planets:
		if is_instance_valid(planet):
			planet.queue_free()

	anchor_planets.clear()
	side_planets.clear()

	highest_anchor_y = 0.0


func _process(_delta: float) -> void:
	if not active:
		return
		
	if player == null:
		return

	if player.global_position.y < highest_anchor_y + GENERATION_DISTANCE:
		_generate_next_anchor()

	_despawn_old_planets()


# =========================================================
# ANCHORS
# =========================================================

func _create_initial_anchor() -> void:
	var radius: float = randf_range(MIN_RADIUS, MAX_RADIUS)

	var index: int = randi_range(0, START_POSITIONS.size() - 1)
	var start_pos: Vector2 = START_POSITIONS[index]

	var planet: Node2D = _spawn_planet(start_pos, radius)

	anchor_planets.append(planet)
	highest_anchor_y = start_pos.y


func _generate_next_anchor() -> void:
	var last_anchor: Node2D = anchor_planets.back()
	var last_radius: float = _get_planet_radius(last_anchor)

	var new_radius: float = randf_range(MIN_RADIUS, MAX_RADIUS)
	var pos: Vector2 = _find_valid_position(
		last_anchor.global_position,
		last_radius,
		new_radius,
		true
	)

	if pos == Vector2.ZERO:
		return

	var planet: Node2D = _spawn_planet(pos, new_radius)
	anchor_planets.append(planet)
	highest_anchor_y = pos.y

	_generate_side_planets(planet)


# =========================================================
# SIDE PLANETS
# =========================================================

func _generate_side_planets(anchor: Node2D) -> void:
	var scale := _get_side_spawn_scale(anchor.global_position.y)

	if randf() < 0.7 * scale:
		_try_spawn_side(anchor)
	if randf() < 0.4 * scale:
		_try_spawn_side(anchor)
	if randf() < 0.1 * scale:
		_try_spawn_side(anchor)


func _try_spawn_side(anchor: Node2D) -> void:
	var anchor_radius: float = _get_planet_radius(anchor)
	var new_radius: float = randf_range(MIN_RADIUS, MAX_RADIUS)

	var pos: Vector2 = _find_valid_position(
		anchor.global_position,
		anchor_radius,
		new_radius,
		false
	)

	if pos == Vector2.ZERO:
		return

	var planet: Node2D = _spawn_planet(pos, new_radius)
	side_planets.append(planet)


# =========================================================
# POSITIONING
# =========================================================

func _find_valid_position(
	origin: Vector2,
	origin_radius: float,
	new_radius: float,
	is_anchor: bool
) -> Vector2:
	var attempts: int = MAX_ANCHOR_ATTEMPTS if is_anchor else MAX_SIDE_ATTEMPTS

	for i in range(attempts):
		var angle: float = randf_range(-PI / 3.0, PI / 3.0)
		var gap: float = _get_gap_for_y(origin.y)


		var direction: Vector2 = Vector2(sin(angle), -cos(angle))

		# surface-to-surface spacing
		var center_dist: float = gap + origin_radius + new_radius
		var pos: Vector2 = origin + direction * center_dist

		if not _overlaps_existing(pos, new_radius):
			return pos

	return Vector2.ZERO


func _overlaps_existing(pos: Vector2, new_radius: float) -> bool:
	for planet in anchor_planets:
		if _circle_overlap(pos, new_radius, planet):
			return true

	for planet in side_planets:
		if _circle_overlap(pos, new_radius, planet):
			return true

	return false


func _circle_overlap(pos: Vector2, new_radius: float, planet: Node2D) -> bool:
	var planet_radius: float = _get_planet_radius(planet)
	return pos.distance_to(planet.global_position) < (
		planet_radius + new_radius + SAFETY_MARGIN
	)


# =========================================================
# SPAWN / DESPAWN
# =========================================================

func _spawn_planet(pos: Vector2, radius: float) -> Node2D:
	var planet: Node2D = planet_scene.instantiate()
	add_child(planet)

	planet.global_position = pos
	planet.set_radius(radius)

	# Start invisible
	planet.modulate.a = 0.0

	var tween := create_tween()
	tween.tween_property(planet, "modulate:a", 1.0, 0.5)

	return planet



func _despawn_old_planets() -> void:
	for planet in side_planets.duplicate():
		if planet.global_position.y > player.global_position.y + DESPAWN_DISTANCE:
			side_planets.erase(planet)
			planet.queue_free()


# =========================================================
# UTIL
# =========================================================
func _get_gap_for_y(y: float) -> float:
	var t := inverse_lerp(GAP_START_Y, GAP_END_Y, y)
	t = clamp(t, 0.0, 1.0)

	var min_gap :float = lerp(MIN_GAP_START, MIN_GAP_END, t)
	var max_gap :float = lerp(MAX_GAP_START, MAX_GAP_END, t)

	return randf_range(min_gap, max_gap)


func _get_planet_radius(planet: Node2D) -> float:
	var col: CollisionShape2D = planet.get_node("CollisionShape2D")
	var shape: CircleShape2D = col.shape
	return shape.radius
	
func _get_side_spawn_scale(y: float) -> float:
	var t := inverse_lerp(SIDE_SPAWN_START_Y, SIDE_SPAWN_END_Y, y)
	t = clamp(t, 0.0, 1.0)
	return lerp(SIDE_SPAWN_SCALE_START, SIDE_SPAWN_SCALE_END, t)
