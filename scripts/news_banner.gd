class_name NewsBanner
extends Label
## A cartoon "news slip" that slides down from the top of the monitor, then slides away.
## Styled to match the game: chunky black outline, hard drop shadow, sticky-note
## yellow, and green/red like the Buy/Sell buttons when the size of the move is known.
## Call show_news("Headline text", impact_pct) whenever a market event happens.

@export var show_seconds: float = 3.0
@export var font_size: int = 24
@export var banner_height: float = 56.0
## Extra gap on the left (pixels) so the sticky note doesn't cover the banner.
## Only used when the banner is inside the graph.
@export var left_inset: float = 150.0
## Slight tilt, like a note stuck on crooked. Set to 0 for perfectly straight.
@export var tilt_degrees: float = -1.5
@export var border_width: int = 4
@export var border_color: Color = Color(0.05, 0.05, 0.05)
@export var shadow_offset: Vector2 = Vector2(4, 5)

@export_group("Colours")
## Default (headline posted, direction unknown): matches the Work Day sticky note.
@export var neutral_color: Color = Color(1.0, 0.94, 0.42)
@export var neutral_text_color: Color = Color(0.08, 0.08, 0.08)
## Used when an impact is passed in. Matches the Buy / Sell buttons.
@export var good_color: Color = Color(0.12, 0.78, 0.15)
@export var bad_color: Color = Color(0.85, 0.08, 0.08)
@export var impact_text_color: Color = Color.WHITE

var _tween: Tween
var _style := StyleBoxFlat.new()


func _ready() -> void:
	visible = false
	z_index = 10   # draw on top of the HUD labels (the sticky note can sit above this)
	autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	clip_text = true
	add_theme_font_size_override("font_size", font_size)

	_style.set_corner_radius_all(12)
	_style.set_border_width_all(border_width)
	_style.border_color = border_color
	_style.set_content_margin_all(10.0)
	# A hard, un-blurred shadow like a cartoon sticker.
	_style.shadow_color = Color(0, 0, 0, 0.4)
	_style.shadow_size = 1
	_style.shadow_offset = shadow_offset
	add_theme_stylebox_override("normal", _style)


## Borrows the font from an existing label (e.g. the Cash label) so the banner
## uses the same lettering as the rest of the game.
func copy_font_from(source: Label) -> void:
	if source == null:
		return
	var f: Font = null
	if source.label_settings != null and source.label_settings.font != null:
		f = source.label_settings.font
	else:
		f = source.get_theme_font("font")
	if f != null:
		add_theme_font_override("font", f)


## impact_pct is the signed size of the move (e.g. +12.0 or -30.0). Use 0 if unknown.
func show_news(headline: String, impact_pct: float = 0.0) -> void:
	if impact_pct > 0.0:
		_style.bg_color = good_color
		add_theme_color_override("font_color", impact_text_color)
	elif impact_pct < 0.0:
		_style.bg_color = bad_color
		add_theme_color_override("font_color", impact_text_color)
	else:
		_style.bg_color = neutral_color
		add_theme_color_override("font_color", neutral_text_color)

	if is_zero_approx(impact_pct):
		text = headline
	else:
		text = "%s  (%+.0f%%)" % [headline, impact_pct]

	# If the banner is a child of a Control (e.g. the price graph), fit inside
	# that Control. Otherwise fit to the whole screen.
	var area_size := get_viewport_rect().size
	var side := 40.0
	var left := 40.0
	var top := 16.0
	var parent_control := get_parent() as Control
	if parent_control:
		area_size = parent_control.size
		side = 8.0
		left = 8.0 + left_inset   # push right, clear of the sticky note
		top = 8.0

	size = Vector2(area_size.x - left - side, banner_height)
	pivot_offset = size / 2.0
	rotation_degrees = tilt_degrees
	var hidden_pos := Vector2(left, -size.y - 20.0)
	var shown_pos := Vector2(left, top)
	position = hidden_pos
	visible = true

	if _tween and _tween.is_running():
		_tween.kill()
	_tween = create_tween()
	_tween.tween_property(self, "position", shown_pos, 0.35) \
			.set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)
	_tween.tween_interval(show_seconds)
	_tween.tween_property(self, "position", hidden_pos, 0.3) \
			.set_trans(Tween.TRANS_CUBIC).set_ease(Tween.EASE_IN)
	_tween.tween_callback(func(): visible = false)
