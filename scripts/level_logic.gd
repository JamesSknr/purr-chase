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
@export var seconds_per_tick: float = 0.33  # about three market ticks per second
@export var starting_cash: float = 1000.0
## Ticks simulated before each round, so the graph has history to show.
@export var warmup_ticks: int = 60
## Which level of events.json to play (1 = the first level).
@export var level_id: int = 1
## The graph is a direct child of this node.
@onready var graph: PriceGraph = $PriceGraph
@onready var price_graph: PriceGraph = $PriceGraph

const SYMBOL := "CAT"

var market: StockMarket
var events: EventManager      # NEW: picks and fires the curated events
var news_banner: NewsBanner   # NEW: on-screen headline banner
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
	_ensure_news_banner()
	start_round()


## Starts a fresh round with a brand-new market. Call this from a menu too.
func start_round() -> void:
	market = StockMarket.new()
	market.event_chance = 0.0   # random news OFF: EventManager drives the events now
	# Stock.new(symbol, price, volatility, beta, mean_reversion)
	market.add_stock(StockMarket.Stock.new(SYMBOL, 100.0, 0.025, 1.0, 0.03))

	# Hand the new market to the EventManager. start_level() also resets the
	# stock's start price / volatility from events.json, so it has to come
	# BEFORE the warm-up below (which builds the price history for the graph).
	_ensure_events()
	events.set_market(market)
	events.market_symbol = SYMBOL
	events.seconds_per_tick = seconds_per_tick
	events.start_level(level_id)

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
	if events:
		events.stop()
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
		


# ---------------------------------------------------------------------
# EVENTS: headlines and visuals (NEW)
# ---------------------------------------------------------------------

## Creates the EventManager once and connects its two signals.
func _ensure_events() -> void:
	if events:
		return
	events = EventManager.new()
	events.name = "EventManager"
	add_child(events)
	events.headline_posted.connect(_on_headline)
	events.event_applied.connect(_on_event_applied)


## Creates the headline banner once. It is a child of the price graph, so it
## slides down from the top edge of the monitor and the graph's clip_contents
## hides it while it is "above" the screen.
func _ensure_news_banner() -> void:
	if news_banner:
		return
	news_banner = NewsBanner.new()
	if graph:
		graph.add_child(news_banner)
	else:
		# Fallback: no graph found, so show it at the top of the whole window.
		var layer := CanvasLayer.new()
		layer.layer = 10
		add_child(layer)
		layer.add_child(news_banner)
	# Use the same lettering as the Cash label so the banner matches the HUD.
	news_banner.copy_font_from(cash_label)


## The headline appears FIRST (this is the player's reaction window)...
func _on_headline(text: String) -> void:
	print("HEADLINE: ", text)
	if news_banner:
		# Grey on purpose: the player has to work out which way the price will go.
		news_banner.show_news(text)


## ...and the price moves a couple of seconds later. Flash the graph to show it.
func _on_event_applied(event: Dictionary) -> void:
	if not round_active:
		return
	var impact := float(event.get("impact", 0.0))
	_flash_graph(impact >= 0.0)


## Only used if market.event_chance is ever turned back on (random news).
func _on_news(_tick: int, _symbol: String, headline: String) -> void:
	print("NEWS: ", headline)
	if news_banner:
		news_banner.show_news(headline)


## Briefly tints the graph green (price jumped up) or red (price dropped).
func _flash_graph(positive: bool) -> void:
	if graph == null:
		return
	# self_modulate tints only the graph's own drawing, not the banner inside it.
	graph.self_modulate = Color(0.55, 1.0, 0.55) if positive else Color(1.0, 0.45, 0.45)
	create_tween().tween_property(graph, "self_modulate", Color.WHITE, 0.9)


## DEBUG (delete later): fakes an event, headline first, price move 2 seconds later.
func _debug_event(headline: String, shape: String, impact: float) -> void:
	_on_headline(headline)
	await get_tree().create_timer(2.0).timeout
	market.apply_event(SYMBOL, shape, impact)
	_on_event_applied({"impact": impact})

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
		Audio.play_neutral_meow()

	# If 'D' key is pressed sell a share
	elif event.keycode == KEY_D:
		current_action = action.SELL
		cat_paw.press_button_tween(sell_button.position)
		sell_share()
		Audio.play_angry_meow()

	# DEBUG (delete later): 1 = fake good news, 2 = fake bad news.
	elif event.keycode == KEY_1:
		_debug_event("TEST: Big buyer arrives!", "spike", 15.0)
	elif event.keycode == KEY_2:
		_debug_event("TEST: Supply scare!", "crash", -20.0)


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
	
