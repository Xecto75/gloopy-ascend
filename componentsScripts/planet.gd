extends StaticBody2D

@onready var collision: CollisionShape2D = $CollisionShape2D
@onready var visual: Node2D = $Visual

#Visual
@onready var base_deep: Sprite2D = $Visual/PlanetDeep
@onready var base_surface: Sprite2D = $Visual/PlanetSurface

@onready var crack1: Sprite2D = $Visual/Crack1

@onready var crack2_deep: Sprite2D = $Visual/Crack2Deep
@onready var crack2_surface: Sprite2D = $Visual/Crack2Surface

@onready var crack3_deep: Sprite2D = $Visual/Crack3Deep
@onready var crack3_surface: Sprite2D = $Visual/Crack3Surface

const BASE_RADIUS := 180.0
const MIN_SPIN_SPEED: float = 0.5
const MAX_SPIN_SPEED: float = 1.0
const STUCK_SPIN_MULT: float = 4.0

var spin_speed: float = 0.0
var base_spin_speed: float = 0.0
var stuck_count: int = 0

const COLOR_SETS := [
	[Color("44ac61"), Color("45c469")],
	[Color("8baa95"), Color("44ac61")],
	[Color("6e7c73"), Color("8baa95")],
	[Color("555956"), Color("6e7c73")],
	[Color("d57b53"), Color("555956")],
	[Color("904f33"), Color("d57b53")],
	[Color("8c334b"), Color("904f33")],
	[Color("732155"), Color("8c334b")],
	[Color("5d3864"), Color("732155")],
	[Color("3f1c45"), Color("5d3864")]
]


func _ready() -> void:
	base_spin_speed = randf_range(MIN_SPIN_SPEED, MAX_SPIN_SPEED)
	if randf() < 0.5:
		base_spin_speed = -base_spin_speed

	spin_speed = base_spin_speed

	var circle := collision.shape as CircleShape2D

func setup_visuals(world_height: float) -> void:
	var level := int(abs(world_height) / SaveData.HEIGHT_PER_LEVEL)
	var visual_level := level + 1

	var color_stage : float = clamp(visual_level / 20, 0, COLOR_SETS.size() - 2)
	var crack_stage := int((visual_level % 20) / 5)

	var current_colors = COLOR_SETS[color_stage]
	var next_colors = COLOR_SETS[color_stage + 1]

	var current_surface: Color = current_colors[1]
	var current_deep: Color = current_colors[0]

	var next_surface: Color = next_colors[1]
	var next_deep: Color = next_colors[0]
	
	base_surface.modulate = current_surface
	base_deep.modulate = current_deep

	crack1.visible = false

	crack2_deep.visible = false
	crack2_surface.visible = false

	crack3_deep.visible = false
	crack3_surface.visible = false

	match crack_stage:
		0:
			pass

		1:
			#print("CRACK 1 START========================")
			crack1.visible = true
			crack1.modulate = current_deep

		2:
			#print("CRACK 2 START========================")
			crack2_deep.visible = true
			crack2_surface.visible = true

			crack2_deep.modulate = next_deep
			crack2_surface.modulate = current_deep

		3:
			#print("CRACK 3 START========================")
			crack3_deep.visible = true
			crack3_surface.visible = true

			crack3_deep.modulate = next_deep
			crack3_surface.modulate = current_deep

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
	visual.scale = Vector2.ONE * scale_factor
