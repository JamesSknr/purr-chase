class_name StockMarket
extends RefCounted
## Random-walk stock market for games (Godot 4).
##
## Each tick, every stock's price is multiplied by exp(log_return), where
## log_return = drift + mean reversion + (beta * market shock) + own noise
##              + news jump - 0.5 * sigma^2
## Prices can never go negative. Pass a seed for a reproducible market.

## Emitted whenever a news event hits a stock. Hook this up to your UI.
signal news_posted(tick: int, symbol: String, headline: String)

## One stock's settings, current price and price history.
class Stock:
	var symbol: String
	var price: float
	var drift: float            ## average return per tick
	var volatility: float       ## base std-dev of per-tick return
	var beta: float             ## sensitivity to the whole-market shock
	var mean_reversion: float   ## 0 = pure random walk, higher = snaps back
	var fair_value: float       ## price the stock is gently pulled toward
	var vol_multiplier: float = 1.0  ## >1 right after news, decays back to 1
	var history: Array[float] = []
	# --- ADDED for curated events (Purr-chase) ---
	var injected_drift: float = 0.0      ## temporary extra drift from a "drift" event
	var injected_ticks_left: int = 0     ## how many ticks the injected drift still runs
	var pending_jump: float = 0.0        ## one-shot log-move queued by spike/crash/pop_fade
	# ---------------------------------------------

	func _init(
			p_symbol: String,
			p_price: float,
			p_volatility: float = 0.012,
			p_beta: float = 1.0,
			p_mean_reversion: float = 0.01,
			p_drift: float = 0.0003) -> void:
		symbol = p_symbol
		price = p_price
		volatility = p_volatility
		beta = p_beta
		mean_reversion = p_mean_reversion
		drift = p_drift
		fair_value = p_price
		history.append(p_price)

	## % change since the previous tick.
	func change_pct() -> float:
		if history.size() < 2:
			return 0.0
		return (history[-1] / history[-2] - 1.0) * 100.0


var stocks: Dictionary = {}          ## symbol (String) -> Stock
var market_volatility: float = 0.006 ## std-dev of the shared market shock
var event_chance: float = 0.01       ## per stock, per tick
var vol_decay: float = 0.9           ## how fast news volatility fades
var price_floor: float = 0.01
var max_history: int = 2000          ## 0 = keep everything
var tick_count: int = 0
var news: Array = []                 ## each entry: [tick, symbol, headline]

var _rng := RandomNumberGenerator.new()


## Pass a seed >= 0 for a reproducible market, or leave as -1 for a random one.
func _init(p_seed: int = -1) -> void:
	if p_seed >= 0:
		_rng.seed = p_seed
	else:
		_rng.randomize()


func add_stock(stock: Stock) -> void:
	stocks[stock.symbol] = stock


func get_stock(symbol: String) -> Stock:
	return stocks.get(symbol)


## Advance the market by one tick. Returns { symbol: new_price }.
func step() -> Dictionary:
	tick_count += 1
	var market_shock := _rng.randfn(0.0, market_volatility)
	var prices := {}

	for symbol in stocks:
		var s: Stock = stocks[symbol]

		# Volatility spike from earlier news fades back toward normal.
		s.vol_multiplier = 1.0 + (s.vol_multiplier - 1.0) * vol_decay

		# Occasional news event: instant jump + volatility spike.
		var jump := 0.0
		if _rng.randf() < event_chance:
			jump = _rng.randfn(0.0, 0.06)
			s.vol_multiplier += absf(jump) * 20.0
			var mood := "surges" if jump > 0.0 else "tumbles"
			var headline := "%s %s on breaking news" % [symbol, mood]
			news.append([tick_count, symbol, headline])
			news_posted.emit(tick_count, symbol, headline)

		# --- ADDED: pull in curated-event effects for this tick ---
		var injected := 0.0
		if s.injected_ticks_left > 0:
			injected = s.injected_drift
			s.injected_ticks_left -= 1
			if s.injected_ticks_left <= 0:
				s.injected_drift = 0.0
		var one_shot := s.pending_jump
		s.pending_jump = 0.0
		# -----------------------------------------------------------

		var sigma := s.volatility * s.vol_multiplier
		var reversion := s.mean_reversion * log(s.fair_value / s.price)
		var noise := _rng.randfn(0.0, sigma)

		var log_return := (s.drift + reversion + s.beta * market_shock
				+ noise + jump + injected + one_shot - 0.5 * sigma * sigma)

		s.price = maxf(price_floor, s.price * exp(log_return))

		s.history.append(s.price)
		if max_history > 0 and s.history.size() > max_history:
			s.history.pop_front()

		prices[symbol] = s.price

	return prices


func run(ticks: int) -> void:
	for i in ticks:
		step()


# ---------------------------------------------------------------------
# ADDED for Purr-chase curated events (drive these from EventManager)
# ---------------------------------------------------------------------

## Inject one of Nishita's events into a stock.
##   shape: "spike" | "crash" | "pop_fade" -> a sharp one-shot jump.
##          ("pop_fade" fades on its own because mean reversion pulls it back.)
##          "drift" -> spreads the move gradually over duration_ticks.
##   impact_pct: signed percentage move for the full effect (e.g. +16, -30).
func apply_event(symbol: String, shape: String, impact_pct: float, duration_ticks: int = 5) -> void:
	var s: Stock = stocks.get(symbol)
	if s == null:
		return
	var r := log(1.0 + impact_pct / 100.0)   # total log-move for the full impact
	match shape:
		"drift":
			var n: int = maxi(1, duration_ticks)
			s.injected_drift += r / n
			s.injected_ticks_left = maxi(s.injected_ticks_left, n)
		_:  # spike, crash, pop_fade
			s.pending_jump += r
			s.vol_multiplier += absf(r) * 15.0   # a little extra wobble around the move


## Re-point the single game stock at the start of each level (new commodity).
func reset_stock(symbol: String, price: float, volatility: float) -> void:
	var s: Stock = stocks.get(symbol)
	if s == null:
		return
	s.price = price
	s.fair_value = price
	s.volatility = volatility
	s.vol_multiplier = 1.0
	s.injected_drift = 0.0
	s.injected_ticks_left = 0
	s.pending_jump = 0.0
	s.history = [price]

class_name StockMarket
extends RefCounted
## Random-walk stock market for games (Godot 4).
##
## Each tick, every stock's price is multiplied by exp(log_return), where
## log_return = drift + mean reversion + (beta * market shock) + own noise
##              + news jump - 0.5 * sigma^2
## Prices can never go negative. Pass a seed for a reproducible market.

## Emitted whenever a news event hits a stock. Hook this up to your UI.
signal news_posted(tick: int, symbol: String, headline: String)

## One stock's settings, current price and price history.
class Stock:
	var symbol: String
	var price: float
	var drift: float            ## average return per tick
	var volatility: float       ## base std-dev of per-tick return
	var beta: float             ## sensitivity to the whole-market shock
	var mean_reversion: float   ## 0 = pure random walk, higher = snaps back
	var fair_value: float       ## price the stock is gently pulled toward
	var vol_multiplier: float = 1.0  ## >1 right after news, decays back to 1
	var history: Array[float] = []

	func _init(
			p_symbol: String,
			p_price: float,
			p_volatility: float = 0.012,
			p_beta: float = 1.0,
			p_mean_reversion: float = 0.01,
			p_drift: float = 0.0003) -> void:
		symbol = p_symbol
		price = p_price
		volatility = p_volatility
		beta = p_beta
		mean_reversion = p_mean_reversion
		drift = p_drift
		fair_value = p_price
		history.append(p_price)

	## % change since the previous tick.
	func change_pct() -> float:
		if history.size() < 2:
			return 0.0
		return (history[-1] / history[-2] - 1.0) * 100.0


var stocks: Dictionary = {}          ## symbol (String) -> Stock
var market_volatility: float = 0.006 ## std-dev of the shared market shock
var event_chance: float = 0.01       ## per stock, per tick
var vol_decay: float = 0.9           ## how fast news volatility fades
var price_floor: float = 0.01
var max_history: int = 2000          ## 0 = keep everything
var tick_count: int = 0
var news: Array = []                 ## each entry: [tick, symbol, headline]

var _rng := RandomNumberGenerator.new()


## Pass a seed >= 0 for a reproducible market, or leave as -1 for a random one.
func _init(p_seed: int = -1) -> void:
	if p_seed >= 0:
		_rng.seed = p_seed
	else:
		_rng.randomize()


func add_stock(stock: Stock) -> void:
	stocks[stock.symbol] = stock


func get_stock(symbol: String) -> Stock:
	return stocks.get(symbol)


## Advance the market by one tick. Returns { symbol: new_price }.
func step() -> Dictionary:
	tick_count += 1
	var market_shock := _rng.randfn(0.0, market_volatility)
	var prices := {}

	for symbol in stocks:
		var s: Stock = stocks[symbol]

		# Volatility spike from earlier news fades back toward normal.
		s.vol_multiplier = 1.0 + (s.vol_multiplier - 1.0) * vol_decay

		# Occasional news event: instant jump + volatility spike.
		var jump := 0.0
		if _rng.randf() < event_chance:
			jump = _rng.randfn(0.0, 0.06)
			s.vol_multiplier += absf(jump) * 20.0
			var mood := "surges" if jump > 0.0 else "tumbles"
			var headline := "%s %s on breaking news" % [symbol, mood]
			news.append([tick_count, symbol, headline])
			news_posted.emit(tick_count, symbol, headline)

		var sigma := s.volatility * s.vol_multiplier
		var reversion := s.mean_reversion * log(s.fair_value / s.price)
		var noise := _rng.randfn(0.0, sigma)

		var log_return := (s.drift + reversion + s.beta * market_shock
				+ noise + jump - 0.5 * sigma * sigma)

		s.price = maxf(price_floor, s.price * exp(log_return))

		s.history.append(s.price)
		if max_history > 0 and s.history.size() > max_history:
			s.history.pop_front()

		prices[symbol] = s.price

	return prices


func run(ticks: int) -> void:
	for i in ticks:
		step()
