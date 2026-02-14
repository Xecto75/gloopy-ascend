extends Node2D

@export var player: CharacterBody2D
@export var cloud_textures: Array[Texture2D]

# --------------------------------------------------
# SPAWN / DESPAWN
# --------------------------------------------------
const SPAWN_STEP_DISTANCE: float = 600.0
const DESPAWN_DISTANCE: float = 3500.0

const MAX_SPAWN_ATTEMPTS: int = 10
const MIN_CLOUD_DISTANCE: float = 300.0

# --------------------------------------------------
# SPAWN BAND (RENDER DISTANCE)
# --------------------------------------------------
const CLOUD_SPAWN_MIN_Y_OFFSET: float = 1500.0
const CLOUD_SPAWN_MAX_Y_OFFSET: float = 3500.0
const CLOUD_X_SPREAD: float = 1200.0

# --------------------------------------------------
# ALTITUDE DENSITY
# --------------------------------------------------
const CLOUD_DENSITY_START_Y: float = -2000.0
const CLOUD_DENSITY_END_Y: float = -60000.0

const CLOUD_DENSITY_MULTIPLIER := 2.0

# --------------------------------------------------
# ALTITUDE FADE (NEW)
# --------------------------------------------------
const CLOUD_FADE_START_Y := -30000.0
const CLOUD_FADE_END_Y   := -60000.0

# --------------------------------------------------
# DRIFT
# --------------------------------------------------
const CLOUD_MIN_DRIFT_SPEED: float = 6.0
const CLOUD_MAX_DRIFT_SPEED: float = 18.0

# --------------------------------------------------
# STATE
# --------------------------------------------------
var clouds: Array[Sprite2D]
var cloud_drift_speed: Array[float]
var cloud_drift_dir: Array[float]

var last_spawn_y: float


func _ready() -> void:
	process_mode = Node.PROCESS_MODE_PAUSABLE

	clouds = []
	cloud_drift_speed = []
	cloud_drift_dir = []
	last_spawn_y = INF


func _process(delta: float) -> void:
	if player == null:
		return

	if last_spawn_y == INF:
		last_spawn_y = player.global_position.y
		return

	while player.global_position.y < last_spawn_y - SPAWN_STEP_DISTANCE:
		last_spawn_y -= SPAWN_STEP_DISTANCE
		_try_spawn_cloud()

	_update_cloud_drift(delta)
	_despawn_old_clouds()
	_update_cloud_opacity() # <-- NEW


# --------------------------------------------------
# DENSITY
# --------------------------------------------------
func _density_at_height(py: float) -> float:
	if py >= CLOUD_DENSITY_START_Y:
		return 1.0
	if py <= CLOUD_DENSITY_END_Y:
		return 0.0
	return inverse_lerp(
		CLOUD_DENSITY_END_Y,
		CLOUD_DENSITY_START_Y,
		py
	)


# --------------------------------------------------
# OPACITY FADE (NEW)
# --------------------------------------------------
func _update_cloud_opacity() -> void:
	var py := player.global_position.y

	var t := (py - CLOUD_FADE_START_Y) / (CLOUD_FADE_END_Y - CLOUD_FADE_START_Y)
	t = clamp(t, 0.0, 1.0)

	var alpha := 1.0 - t

	for c in clouds:
		c.modulate.a = alpha


# --------------------------------------------------
# SPAWNING
# --------------------------------------------------
func _try_spawn_cloud() -> void:
	var py: float = player.global_position.y
	var density : float = clamp(
		_density_at_height(py) * CLOUD_DENSITY_MULTIPLIER,
		0.0,
		1.0
	)

	if density <= 0.0:
		return

	for i in range(MAX_SPAWN_ATTEMPTS):
		var pos: Vector2 = _random_cloud_position()
		if _is_position_valid(pos):
			if randf() <= density:
				var cloud := _spawn_cloud(pos)
				clouds.append(cloud)
			return


func _random_cloud_position() -> Vector2:
	var px: float = player.global_position.x
	var py: float = player.global_position.y

	return Vector2(
		px + randf_range(-CLOUD_X_SPREAD, CLOUD_X_SPREAD),
		py - randf_range(CLOUD_SPAWN_MIN_Y_OFFSET, CLOUD_SPAWN_MAX_Y_OFFSET)
	)


func _is_position_valid(pos: Vector2) -> bool:
	for c: Sprite2D in clouds:
		if c.global_position.distance_to(pos) < MIN_CLOUD_DISTANCE:
			return false
	return true


# --------------------------------------------------
# DRIFT
# --------------------------------------------------
func _update_cloud_drift(delta: float) -> void:
	for i in range(clouds.size()):
		clouds[i].global_position.x += cloud_drift_dir[i] * cloud_drift_speed[i] * delta


# --------------------------------------------------
# DESPAWN
# --------------------------------------------------
func _despawn_old_clouds() -> void:
	for i in range(clouds.size() - 1, -1, -1):
		var c := clouds[i]
		if c.global_position.y > player.global_position.y + DESPAWN_DISTANCE:
			c.queue_free()
			clouds.remove_at(i)
			cloud_drift_speed.remove_at(i)
			cloud_drift_dir.remove_at(i)


# --------------------------------------------------
# CREATE
# --------------------------------------------------
func _spawn_cloud(pos: Vector2) -> Sprite2D:
	var cloud := Sprite2D.new()
	cloud.texture = cloud_textures.pick_random()
	cloud.centered = true
	cloud.z_index = -10
	cloud.global_position = pos
	add_child(cloud)

	cloud_drift_speed.append(
		randf_range(CLOUD_MIN_DRIFT_SPEED, CLOUD_MAX_DRIFT_SPEED)
	)
	cloud_drift_dir.append(-1.0 if randf() < 0.5 else 1.0)

	return cloud
