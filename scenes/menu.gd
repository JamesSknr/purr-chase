extends Node2D

@onready var cat_paw: Control = $CatPaw

@onready var play_button: Node2D = $PlayButton
@onready var quit_button: Node2D = $QuitButton
@onready var profit_label: RichTextLabel = $ProfitLabel

# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	Audio.play_menu_music()
	profit_label.text = "Current profit: $%.2f" % Audio.total_profit
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
		await cat_paw.move_to_button(play_button.position)
		play_button.press_button_tween()
		await cat_paw.press_and_return()
		SceneTransition.change_scene_to_file("res://scenes/test_scene.tscn")


	# If 'D' key is pressed sell a share
	elif event.keycode == KEY_D:

			await cat_paw.move_to_button(quit_button.position)
			quit_button.press_button_tween()
			await cat_paw.press_and_return()
			get_tree().quit()
