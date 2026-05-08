extends Node2D

@export var peak_height := 900.0
@export var rise_time := 0.55
@export var fall_time := 0.45

@onready var area := $Area2D
@onready var flame: AnimatedSprite2D = $Flame


var start_y := 0.0
var peak_y := 0.0
var end_y := 0.0


func _ready() -> void:
	visible = false

func launch(from_y: float) -> void:
	visible = true
	flame.play("default")
	
	start_y = from_y
	peak_y = from_y - peak_height
	end_y = from_y

	global_position.y = start_y

	var tween := create_tween()

	# rise
	tween.tween_property(
		self,
		"global_position:y",
		peak_y,
		rise_time
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	# fall
	tween.tween_property(
		self,
		"global_position:y",
		end_y,
		fall_time
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await tween.finished

	queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:

	if not body.has_method("_die"):
		return

	body._die()
