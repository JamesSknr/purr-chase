extends Node2D
enum action {BUY, SELL, HOLD}
var current_action = action.HOLD

@onready var cat_paw: Cat = $CatPaw
@onready var buy_button: Node2D = $BuyButton
@onready var sell_button: Node2D = $SellButton



# Called when the node enters the scene tree for the first time.
func _ready() -> void:
	pass

func _unhandled_input(event):
	if event is InputEventKey:
		
		# If 'A' key is pressed buy a share
		if event.pressed and event.keycode == KEY_A:
			current_action = action.BUY
			cat_paw.press_button_tween(buy_button.position)
		
			buy_share()
			
		# If 'D' key is pressed sell a share
		if event.pressed and event.keycode == KEY_D:
			current_action = action.SELL
			cat_paw.press_button_tween(sell_button.position)
			sell_share()
			
		else:
			current_action = action.HOLD


func buy_share() -> void:
	print("YOU BOUGHT A SHARE")
	current_action = action.HOLD
	
	
func sell_share() -> void:
	print("YOU SOLD A SHARE")
	current_action = action.HOLD
