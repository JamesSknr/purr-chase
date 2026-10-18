class_name NewsBanner
extends TextureRect
## A cartoon "news slip" PNG sprite that slides down from the top, then slides away,
## with text displayed over the top of it.
## Call show_news("Headline text", impaact_pct) whenever a market event happens.

@export var show_seconds: float = 3.0
@export var font_size: int = 16
@export var banner_height: float = 56.0
## Extra gap on the left (pixels) so the sticky note doesn't cover the banner.
## Only used when the banner is inside the graph.
@export var left_inset: float = 150.0
## Slight tilt, like a note stuck on crooked. Set to 0 for perfectly straight.
@export var tilt_degrees: float = 0

@export var banner_texture: Texture2D = preload("res://art/News Notification.png")


@export_group("Colours")
## Default (headline posted, direction unknown): matches the Work Day sticky note.
@export var neutral_color: Color = Color(1.0, 1.0, 1.0, 1.0)
@export var neutral_text_color: Color = Color(1.0, 1.0, 1.0, 1.0)
## Used when an impact is passed in. Matches the Buy / Sell buttons.
@export var good_color: Color = Color(0.12, 0.78, 0.15)
@export var bad_color: Color = Color(0.85, 0.08, 0.08)
@export var impact_text_color: Color = Color.WHITE

var _tween: Tween
var _label: Label


func _ready() -> void:
	if banner_texture:
		texture = banner_texture
	
	visible = false
	z_index = 10   # draw on top of the HUD labels
	mouse_filter = Control.MOUSE_FILTER_IGNORE
	expand_mode = TextureRect.EXPAND_IGNORE_SIZE
	stretch_mode = TextureRect.STRETCH_KEEP_ASPECT_CENTERED

	# Foreground text label displayed over the top of the sprite
	_label = Label.new()
	_label.set_anchors_and_offsets_preset(Control.PRESET_FULL_RECT)
	_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	_label.mouse_filter = Control.MOUSE_FILTER_IGNORE
	_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	_label.clip_text = true
	_label.add_theme_font_size_override("font_size", font_size)
	add_child(_label)


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
		_label.add_theme_font_override("font", f)


## impact_pct is the signed size of the move (e.g. +12.0 or -30.0). Use 0 if unknown.
func show_news(headline: String, impact_pct: float = 0.0) -> void:
	if impact_pct > 0.0:
		self.modulate = good_color
		_label.add_theme_color_override("font_color", impact_text_color)
	elif impact_pct < 0.0:
		self.modulate = bad_color
		_label.add_theme_color_override("font_color", impact_text_color)
	else:
		self.modulate = neutral_color
		_label.add_theme_color_override("font_color", neutral_text_color)

	if is_zero_approx(impact_pct):
		_label.text = headline
	else:
		_label.text = "%s  (%+.0f%%)" % [headline, impact_pct]

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
	
