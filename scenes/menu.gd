extends Node2D
@onready var cat_paw: Cat = $CatPaw

@onready var play_button: Button = $PlayButton
@onready var quit_button: Button = $QuitButton

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _unhandled_input(event):
	# 'not event.echo' stops a held-down key from repeating the action.
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	# If 'A' key is pressed buy a share
	if event.keycode == KEY_A:
		cat_paw.press_button_tween(play_button.position)

	# If 'D' key is pressed sell a share
	elif event.keycode == KEY_D:

		cat_paw.press_button_tween(quit_button.position)


func _on_play_button_pressed() -> void:
	$ButtonClick.play()
	get_tree().change_scene_to_file("res://scenes/test_scene.tscn")



func _on_quit_button_pressed() -> void:
	$ButtonClick.play()
	get_tree().quit()
