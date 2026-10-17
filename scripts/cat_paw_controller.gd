extends Control
class_name Cat

@export var press_distance: float = 120.0
@export var move_duration: float = 0.1
@export var press_pause: float = 0.08

@export var idle_movement: float = 5.0
@export var idle_duration: float = 1.5

var original_position: Vector2
var tween: Tween
var idle_tween: Tween


func _ready() -> void:
	original_position = position
	play_idle_animation()


func play_idle_animation() -> void:
	if idle_tween and idle_tween.is_running():
		idle_tween.kill()

	idle_tween = create_tween()
	idle_tween.set_loops()

	idle_tween.tween_property(
		self,
		"position:y",
		original_position.y - idle_movement,
		idle_duration / 2.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	idle_tween.tween_property(
		self,
		"position:y",
		original_position.y,
		idle_duration / 2.0
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func press_button_tween(button_position: Vector2) -> void:
	# Stop idle movement while the paw is pressing
	if idle_tween and idle_tween.is_running():
		idle_tween.kill()

	# Prevent overlapping press animations
	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()

	# 1. Move to the button
	tween.tween_property(
		self,
		"position",
		button_position,
		move_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	# 2. Press down
	tween.tween_property(
		self,
		"scale",
		Vector2(0.9, 0.9),
		0.08
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	# Hold the pressed position
	tween.tween_interval(press_pause)

	# 3. Return to original position and scale
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

	# Resume idle movement after the press animation finishes
	tween.chain().tween_callback(play_idle_animation)
