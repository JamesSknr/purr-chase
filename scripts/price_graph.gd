class_name PriceGraph
extends Control
## Simple live line graph for a stock price. No addon needed.
## Call add_point(price) on every market tick, or set_points(history) to load a series.

@export var max_points: int = 60
@export var line_color: Color = Color(0.3, 1.0, 0.5)
@export var line_width: float = 3.0
@export var grid_color: Color = Color(1, 1, 1, 0.12)
@export var label_color: Color = Color(1, 1, 1, 0.7)
@export var padding: float = 12.0
@export var show_grid: bool = true
@export var show_labels: bool = true

var _points: Array[float] = []


func _ready() -> void:
	clip_contents = true
	resized.connect(queue_redraw)


## Add the newest price to the right-hand end of the line.
func add_point(price: float) -> void:
	_points.append(price)
	_trim()
	queue_redraw()


## Replace the whole line, e.g. with a stock's history array.
func set_points(values: Array) -> void:
	_points.clear()
	for v in values:
		_points.append(float(v))
	_trim()
	queue_redraw()


func _trim() -> void:
	while _points.size() > max_points:
		_points.pop_front()


func _draw() -> void:
	var area := Rect2(Vector2(padding, padding), size - Vector2(padding, padding) * 2.0)
	if area.size.x <= 0.0 or area.size.y <= 0.0:
		return

	if show_grid:
		for i in 5:
			var gy := area.position.y + area.size.y * i / 4.0
			draw_line(Vector2(area.position.x, gy), Vector2(area.end.x, gy), grid_color, 1.0)

	if _points.size() < 2:
		return

	# Work out the vertical range, with a little breathing room top and bottom.
	var lo: float = _points.min()
	var hi: float = _points.max()
	var span := maxf(hi - lo, 0.01)   # avoids dividing by zero on a flat line
	lo -= span * 0.1
	hi += span * 0.1
	span = hi - lo

	var line := PackedVector2Array()
	for i in _points.size():
		var x := area.position.x + area.size.x * i / float(_points.size() - 1)
		var y := area.end.y - area.size.y * (_points[i] - lo) / span
		line.append(Vector2(x, y))
	draw_polyline(line, line_color, line_width, true)

	if show_labels:
		var font := ThemeDB.fallback_font
		draw_string(font, Vector2(area.position.x + 4.0, area.position.y + 14.0),
				"%.2f" % hi, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, label_color)
		draw_string(font, Vector2(area.position.x + 4.0, area.end.y - 4.0),
				"%.2f" % lo, HORIZONTAL_ALIGNMENT_LEFT, -1.0, 14, label_color)
