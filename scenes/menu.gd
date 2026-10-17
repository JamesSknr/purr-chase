extends Node2D
@onready var cat_paw_sprite: Sprite2D = $CatPawSprite


# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_HIDDEN)
	pass


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func _input(event):
	# Mouse in viewport coordinates.
	if event is InputEventMouseButton:
		print("Mouse Click/Unclick at: ", event.position)
	elif event is InputEventMouseMotion:
		print("Mouse Motion at: ", event.position)
		cat_paw_sprite.position = event.position + Vector2(0,120)

	# Print the size of the viewport.
	print("Viewport Resolution is: ", get_viewport().get_visible_rect().size)


func _on_play_button_pressed() -> void:
	get_tree().change_scene_to_file("res://scenes/test_scene.tscn")



func _on_quit_button_pressed() -> void:
	get_tree().quit()
