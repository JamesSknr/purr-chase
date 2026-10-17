extends Node2D

@onready var sell_button: Sprite2D = $SellButton
@onready var button_base: Sprite2D = $ButtonBase
var tween: Tween
var original_buy_button_y: float
# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	var original_buy_button_y = sell_button.position.y


# Called every frame. 'delta' is the elapsed time since the previous frame.
func _process(delta: float) -> void:
	pass


func press_button_tween() -> void:
	$"../ButtonClick".play()
	if tween and tween.is_running():
		tween.kill()

	sell_button.position.y = original_buy_button_y

	tween = create_tween()
	#tween.tween_interval(0.25)
	tween.tween_property(sell_button, "position:y", original_buy_button_y + 8.0, 0.1)
	tween.tween_property(sell_button, "position:y", original_buy_button_y, 0.1)
