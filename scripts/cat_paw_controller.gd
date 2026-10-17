extends Control
class_name Cat

@export var press_distance: float = 120.0
@export var move_duration: float = 0.25
@export var press_pause: float = 0.08

var original_position: Vector2
var tween: Tween


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	original_position = position


func press_button_tween(button_position: Vector2) -> void:
	# Prevent overlapping animations
	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()

	# 1. Move to the button at normal size
	tween.tween_property(
		self,
		"position",
		button_position,
		move_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 2. Press down: small scale pop
	tween.tween_property(
		self,
		"scale",
		Vector2(0.9, 0.9),
		0.08
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Briefly hold the pressed position
	tween.tween_interval(press_pause)

	# 3. Return to the original position and normal size
	tween.set_parallel(true)

	tween.tween_property(
		self,
		"position",
		original_position,
		move_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN_OUT)

	tween.tween_property(
		self,
		"scale",
		Vector2.ONE,
		0.15
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
