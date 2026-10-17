extends Node2D
class_name BigButton

@export var button_name: String = ""
@export var button_color: Color = Color.WHITE
@onready var label: Label = $Label
@onready var button_sprite: ColorRect = $ButtonSprite




# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	label.text = button_name
	button_sprite.color = button_color


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass
