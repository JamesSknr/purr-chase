extends Node
class_name EventManager

## Drives Euan's StockMarket with Nishita's curated events from events.json.
## Flow per event: pick a weighted-random event -> post the headline ->
## wait `delay` seconds (the player's reaction window) -> inject the move into
## the market -> maybe fire a chain.
##
## SETUP (from level_logic, see the wiring snippet):
##   market.event_chance = 0.0          # turn OFF Euan's random news
##   var events := EventManager.new()
##   add_child(events)
##   events.set_market(market)          # hand it Euan's StockMarket
##   events.market_symbol = SYMBOL      # the key level_logic trades, e.g. "CAT"
##   events.seconds_per_tick = seconds_per_tick
##   events.headline_posted.connect(_on_news)   # route headlines to the ticker
##   events.start_level(1)
##
## Hook these signals up in the UI:
##   headline_posted(text)  -> show it in the news ticker
##   event_applied(event)   -> optional (sound, cat reaction, flash the graph)

signal headline_posted(text: String)
signal event_applied(event: Dictionary)

@export var events_path: String = "res://data/events.json"
## The stock key the market/level_logic uses (so events hit the right stock).
@export var market_symbol: String = "CAT"
## Should match level_logic's seconds_per_tick, to turn durations into ticks.
@export var seconds_per_tick: float = 1.0

var _market                       # Euan's StockMarket (RefCounted), set via set_market()
var _levels: Dictionary = {}
var _pool: Array = []
var _interval_min: float = 7.0
var _interval_max: float = 11.0
var _time_to_next: float = 0.0
var _recent: Array = []
const RECENT_MEMORY: int = 3
var _rng := RandomNumberGenerator.new()
var _running: bool = false


func _ready() -> void:
	_rng.randomize()
	_load_events()


func set_market(market) -> void:
	_market = market


func _load_events() -> void:
	if not FileAccess.file_exists(events_path):
		push_error("EventManager: events.json not found at %s" % events_path)
		return
	var txt := FileAccess.get_file_as_string(events_path)
	var parsed = JSON.parse_string(txt)
	if parsed == null or not (parsed is Dictionary) or not parsed.has("levels"):
		push_error("EventManager: events.json is malformed")
		return
	_levels = parsed["levels"]


## Begin a level, e.g. start_level(1). Re-points the stock at the new commodity.
func start_level(level_id) -> void:
	var key := str(level_id)
	if not _levels.has(key):
		push_error("EventManager: no level '%s' in events.json" % key)
		return
	var lvl: Dictionary = _levels[key]
	_pool = lvl.get("events", [])
	var interval: Array = lvl.get("event_interval", [7, 11])
	_interval_min = float(interval[0])
	_interval_max = float(interval[1])
	_recent.clear()
	_time_to_next = _rng.randf_range(_interval_min, _interval_max)
	_running = true
	if _market and _market.has_method("reset_stock"):
		_market.reset_stock(market_symbol,
				float(lvl.get("start_price", 100.0)),
				float(lvl.get("volatility", 0.015)))


func stop() -> void:
	_running = false


func _process(delta: float) -> void:
	if not _running or _pool.is_empty():
		return
	_time_to_next -= delta
	if _time_to_next <= 0.0:
		_fire_event(_pick_event())
		_time_to_next = _rng.randf_range(_interval_min, _interval_max)


func _pick_event() -> Dictionary:
	var candidates: Array = []
	var total: float = 0.0
	for e in _pool:
		var w: float = float(e.get("weight", 1))
		if w <= 0.0:
			continue
		if _recent.has(e.get("id", "")):
			continue
		candidates.append(e)
		total += w
	if candidates.is_empty():
		for e in _pool:
			if float(e.get("weight", 1)) > 0.0:
				candidates.append(e)
				total += float(e.get("weight", 1))
	if candidates.is_empty():
		return {}
	var roll: float = _rng.randf() * total
	for e in candidates:
		roll -= float(e.get("weight", 1))
		if roll <= 0.0:
			return e
	return candidates[0]


func _fire_event(e: Dictionary) -> void:
	if e.is_empty():
		return
	_remember(e.get("id", ""))
	emit_signal("headline_posted", e.get("headline", ""))

	# The delay is the reaction window: headline now, price moves later.
	await get_tree().create_timer(float(e.get("delay", 2.0))).timeout

	if _market and _market.has_method("apply_event"):
		var dur_ticks: int = maxi(1, int(round(float(e.get("duration", 5.0)) / maxf(seconds_per_tick, 0.0001))))
		_market.apply_event(market_symbol,
				String(e.get("shape", "drift")),
				float(e.get("impact", 0.0)),
				dur_ticks)
	emit_signal("event_applied", e)

	if e.has("chain"):
		var chain: Dictionary = e["chain"]
		await get_tree().create_timer(float(chain.get("delay", 3.0))).timeout
		var next_e := _find_by_id(chain.get("event", ""))
		if not next_e.is_empty():
			_fire_event(next_e)


func _find_by_id(id: String) -> Dictionary:
	for e in _pool:
		if e.get("id", "") == id:
			return e
	return {}


func _remember(id: String) -> void:
	if id == "":
		return
	_recent.append(id)
	while _recent.size() > RECENT_MEMORY:
		_recent.pop_front()
