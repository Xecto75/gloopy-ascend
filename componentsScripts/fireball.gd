# fireball.gd
extends Node2D

@export var peak_height := 900.0
@export var rise_time := 0.55
@export var fall_time := 0.45

@onready var flame: AnimatedSprite2D = $Flame

func _ready() -> void:
	modulate.a = 0.0


func launch(from_y: float) -> void:

	modulate.a = 1.0

	flame.play("default")

	var peak_y := from_y - peak_height

	global_position.y = from_y

	var tween := create_tween()

	tween.tween_property(
		self,
		"global_position:y",
		peak_y,
		rise_time
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_OUT)

	tween.tween_property(
		self,
		"global_position:y",
		from_y,
		fall_time
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	await tween.finished

	queue_free()


func _on_area_2d_body_entered(body: Node2D) -> void:
	print("col with fireball")

	if not body.has_method("_die"):
		return

	body._die()
