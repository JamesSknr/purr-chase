extends Node2D

@onready var cat_paw: Sprite2D = $CatPaw

var press_pause := 0.1
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _input(event):
	# Mouse in viewport coordinates.
	if event is InputEventMouseButton:
		print("Mouse Click/Unclick at: ", event.position)
		press_pop_tween()
	elif event is InputEventMouseMotion:
		cat_paw.position = event.position

		var target_rotation = remap(
			event.position.x,
			0.0,
			get_viewport_rect().size.x,
			-PI / 2.0,
			PI / 2.0
		)

		target_rotation = clampf(target_rotation, deg_to_rad(-30.0), deg_to_rad(30.0))

		cat_paw.rotation = lerp_angle(
			cat_paw.rotation,
			target_rotation,
			0.1
		)

	# Print the size of the viewport.
	print("Viewport Resolution is: ", get_viewport().get_visible_rect().size)
	
	

func press_pop_tween() -> void:
	var pop_tween = create_tween()

	pop_tween.tween_property(
		cat_paw,
		"scale",
		Vector2(0.13,0.13),
		0.08
	).set_trans(Tween.TRANS_QUAD).set_ease(Tween.EASE_IN)

	pop_tween.tween_interval(press_pause)

	pop_tween.tween_property(
		cat_paw,
		"scale",
		Vector2(0.145,0.145),
		0.15
	).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
