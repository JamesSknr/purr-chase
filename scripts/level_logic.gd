extends Node2D
enum action {BUY, SELL, HOLD}
var current_action = action.HOLD

@onready var cat_paw: Cat = $CatPaw
@onready var buy_button = $BuyButton
@onready var sell_button = $SellButton


# ---------------------------------------------------------------------
# ROUNDS + MARKET
# ---------------------------------------------------------------------

## Emitted on every market tick, in case anything else wants the price.
signal price_changed(symbol: String, price: float)
## Emitted when a round begins / ends. Hook a menu or results screen to these.
signal round_started
signal round_ended(final_net_worth: float, profit: float)

@export var round_length: float = 60.0      # seconds per round
@export var seconds_per_tick: float = 0.5   # two market tick per second
@export var starting_cash: float = 1000.0
## Ticks simulated before each round, so the graph has history to show.
@export var warmup_ticks: int = 60
## Optional: drag the PriceGraph node onto this in the Inspector.
@onready var graph: PriceGraph = $PriceGraph

const SYMBOL := "CAT"

var market: StockMarket
var cash: float = 0.0
var shares: int = 0
var time_left: float = 0.0
var round_active: bool = false
var _tick_accum: float = 0.0

# Optional HUD: add Label nodes with these exact names as children of this node.
@onready var price_label: Label = get_node_or_null("PriceLabel") as Label
@onready var cash_label: Label = get_node_or_null("CashLabel") as Label
@onready var shares_label: Label = get_node_or_null("SharesLabel") as Label
@onready var result_label: Label = get_node_or_null("ResultLabel") as Label
# The countdown is shown on the existing CLOCK label (ClockTemp > Label).
@onready var clock_label: Label = get_node_or_null("ClockTemp/Label") as Label


func _ready() -> void:
	start_round()


## Starts a fresh round with a brand-new market. Call this from a menu too.
func start_round() -> void:
	market = StockMarket.new()
	market.event_chance = 0.04   # about 2-3 news events per 60-second round
	# Stock.new(symbol, price, volatility, beta, mean_reversion)
	# Short rounds need big, quick swings, and some pull back toward $100
	# so there are real chances to buy low and sell high.
	market.add_stock(StockMarket.Stock.new(SYMBOL, 100.0, 0.025, 1.0, 0.03))
	market.run(warmup_ticks)
	market.news_posted.connect(_on_news)

	cash = starting_cash
	shares = 0
	time_left = round_length
	_tick_accum = 0.0
	round_active = true

	if result_label:
		result_label.text = ""
	if graph:
		graph.set_points(market.get_stock(SYMBOL).history)
	_update_hud()
	_update_clock()
	round_started.emit()


func end_round() -> void:
	round_active = false
	time_left = 0.0
	_update_clock()

	var worth := net_worth()   # any shares you still hold count at the current price
	var profit := worth - starting_cash
	var message := "ROUND OVER\nFinal net worth: $%.2f\nProfit: %s$%.2f\nPress SPACE to play again" \
			% [worth, "+" if profit >= 0.0 else "-", absf(profit)]
	print(message)
	if result_label:
		result_label.text = message
	round_ended.emit(worth, profit)


func _process(delta: float) -> void:
	if not round_active:
		return

	time_left = maxf(time_left - delta, 0.0)

	_tick_accum += delta
	while _tick_accum >= seconds_per_tick:
		_tick_accum -= seconds_per_tick
		market.step()
		var price := current_price()
		price_changed.emit(SYMBOL, price)
		if graph:
			graph.add_point(price)
		_update_hud()

	_update_clock()
	if time_left <= 0.0:
		end_round()


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


func _update_clock() -> void:
	if clock_label:
		var secs := ceili(time_left)
		clock_label.text = "%d:%02d" % [floori(secs / 60.0), secs % 60]


func _on_news(_tick: int, _symbol: String, headline: String) -> void:
	print("NEWS: ", headline)

# ---------------------------------------------------------------------


func _unhandled_input(event):
	# 'not event.echo' stops a held-down key from repeating the action.
	if not (event is InputEventKey and event.pressed and not event.echo):
		return

	# Between rounds, SPACE starts the next one.
	if not round_active:
		if event.keycode == KEY_SPACE:
			start_round()
		return

	# If 'A' key is pressed buy a share
	if event.keycode == KEY_A:
		current_action = action.BUY
		cat_paw.press_button_tween(buy_button.position)
		buy_share()

	# If 'D' key is pressed sell a share
	elif event.keycode == KEY_D:
		current_action = action.SELL
		cat_paw.press_button_tween(sell_button.position)
		sell_share()


func buy_share() -> void:
	var price := current_price()
	if cash >= price:
		cash -= price
		shares += 1
		print("YOU BOUGHT A SHARE at $%.2f | cash $%.2f | shares %d | net worth $%.2f"
				% [price, cash, shares, net_worth()])
	else:
		print("NOT ENOUGH CASH (need $%.2f, have $%.2f)" % [price, cash])
	current_action = action.HOLD
	_update_hud()
	buy_button.press_button_tween()


func sell_share() -> void:
	var price := current_price()
	if shares > 0:
		shares -= 1
		cash += price
		print("YOU SOLD A SHARE at $%.2f | cash $%.2f | shares %d | net worth $%.2f"
				% [price, cash, shares, net_worth()])
	else:
		print("NO SHARES TO SELL")
	current_action = action.HOLD
	_update_hud()
	sell_button.press_button_tween()
