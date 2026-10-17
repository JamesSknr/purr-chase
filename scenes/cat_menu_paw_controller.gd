extends Control

# THIS IS FOR THE CAT PAW JUST ON THE MENU!

@export var press_distance: float = 120.0
@export var move_duration: float = 0.2
@export var press_pause: float = 0.08
@export var idle_distance: float = 5.0
@export var idle_duration: float = 1.2

var original_position: Vector2
var tween: Tween
var idle_tween: Tween


func _ready() -> void:
	original_position = position
	start_idle_animation()


func start_idle_animation() -> void:
	if idle_tween and idle_tween.is_running():
		idle_tween.kill()

	idle_tween = create_tween()
	idle_tween.set_loops()

	idle_tween.tween_property(
		self,
		"position:y",
		original_position.y - idle_distance,
		idle_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)

	idle_tween.tween_property(
		self,
		"position:y",
		original_position.y,
		idle_duration
	).set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)


func stop_idle_animation() -> void:
	if idle_tween and idle_tween.is_running():
		idle_tween.kill()


func move_to_button(button_position: Vector2) -> void:
	stop_idle_animation()

	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()
	tween.tween_property(
		self,
		"position",
		button_position,
		move_duration
	).set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_OUT)

	await tween.finished


func press_and_return() -> void:
	if tween and tween.is_running():
		tween.kill()

	tween = create_tween()

	# Press bump
	tween.tween_property(
		self,
		"scale",
		Vector2(0.9, 0.9),
		0.08
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	tween.tween_interval(press_pause)

	# Return to original position and scale
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

	await tween.finished

	start_idle_animation()
