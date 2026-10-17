extends Node2D
enum action {BUY, SELL, HOLD}
var current_action = action.HOLD

@onready var cat_paw: Cat = $CatPaw
@onready var buy_button: BigButton = $BuyButton
@onready var sell_button: BigButton = $SellButton


# ---------------------------------------------------------------------
# MARKET INTEGRATION
# ---------------------------------------------------------------------

## Emitted on every market tick. A graph or HUD can connect to this.
signal price_changed(symbol: String, price: float)

@export var seconds_per_tick: float = 1.0
@export var starting_cash: float = 1000.0

const SYMBOL := "CAT"

# Use StockMarket.new(42) instead for the same prices every run (good for testing).
var market := StockMarket.new()
var cash: float = 0.0
var shares: int = 0
var _tick_accum: float = 0.0

# Optional HUD: add Label nodes with these exact names as children of this node.
@onready var price_label: Label = get_node_or_null("PriceLabel") as Label
@onready var cash_label: Label = get_node_or_null("CashLabel") as Label
@onready var shares_label: Label = get_node_or_null("SharesLabel") as Label
# Curated-event headline ticker (add a Label named "HeadlineLabel" as a child).
@onready var headline_label: Label = get_node_or_null("HeadlineLabel") as Label


func _process(delta: float) -> void:
	_tick_accum += delta
	while _tick_accum >= seconds_per_tick:
		_tick_accum -= seconds_per_tick
		market.step()
		price_changed.emit(SYMBOL, current_price())
		print("[debug] market tick %d: %s $%.2f" % [market.tick_count, SYMBOL, current_price()])
		_update_hud()


func current_price() -> float:
	return market.get_stock(SYMBOL).price


func net_worth() -> float:
	return cash + shares * current_price()


func _update_hud() -> void:
	var stock := market.get_stock(SYMBOL)
	if price_label:
		price_label.text = "%s $%.2f (%+.1f%%)" % [SYMBOL, stock.price, stock.change_pct()]
	if cash_label:
		cash_label.text = "Cash $%.2f" % cash
	if shares_label:
		shares_label.text = "Shares: %d" % shares


func _on_news(_tick: int, _symbol: String, headline: String) -> void:
	print("NEWS: ", headline)


# Headlines from the curated EventManager land here.
func _on_headline(headline: String) -> void:
	print("NEWS: ", headline)
	if headline_label:
		headline_label.text = headline

# ---------------------------------------------------------------------


# Called when the node enters the scene tree for the first time.
func _ready() -> void:

	cash = starting_cash
	#                           symbol  price  volatility  beta
	market.add_stock(StockMarket.Stock.new(SYMBOL, 100.0, 0.015, 1.0))
	market.news_posted.connect(_on_news)

	# --- Curated events (Nishita): turn off random news, drive from events.json ---
	market.event_chance = 0.0
	var events := EventManager.new()
	add_child(events)
	events.set_market(market)
	events.market_symbol = SYMBOL
	events.seconds_per_tick = seconds_per_tick
	events.headline_posted.connect(_on_headline)
	events.start_level(1)   # change to 2..5 to test the other commodities
	# ------------------------------------------------------------------------------

	_update_hud()


# DEBUG ONLY: runs before the UI sees the key. If this prints but
# _unhandled_input below does not, a UI node is eating the keys.
func _input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		print("[debug] key reached _input: ", event.as_text_keycode())

func _unhandled_input(event):
	if event is InputEventKey and event.pressed and not event.echo:
		print("[debug] key reached _unhandled_input: ", event.as_text_keycode())

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
	buy_button.press_button_tween()
	
	
func sell_share() -> void:
	print("YOU SOLD A SHARE")
	current_action = action.HOLD
	sell_button.press_button_tween()
