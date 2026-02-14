extends StaticBody2D

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var sprite: Sprite2D = $Sprite2D

const BASE_RADIUS := 180.0
const MIN_SPIN_SPEED: float = 0.5
const MAX_SPIN_SPEED: float = 1.0
const STUCK_SPIN_MULT: float = 4.0

var spin_speed: float = 0.0
var base_spin_speed: float = 0.0
var stuck_count: int = 0


func _ready() -> void:
	base_spin_speed = randf_range(MIN_SPIN_SPEED, MAX_SPIN_SPEED)
	if randf() < 0.5:
		base_spin_speed = -base_spin_speed

	spin_speed = base_spin_speed

	var circle := collision.shape as CircleShape2D


func _physics_process(delta: float) -> void:
	var mult := STUCK_SPIN_MULT if stuck_count > 0 else 1.0
	rotation += spin_speed * mult * delta


func on_player_stick() -> void:
	stuck_count += 1


func on_player_unstick() -> void:
	stuck_count = max(0, stuck_count - 1)
	
func set_radius(radius: float) -> void:
	# collision (unique per instance)
	var circle := collision.shape.duplicate() as CircleShape2D
	circle.radius = radius
	collision.shape = circle

	# visual (match sprite size to collision)
	var scale_factor := radius / BASE_RADIUS
	sprite.scale = Vector2.ONE * scale_factor
