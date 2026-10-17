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
