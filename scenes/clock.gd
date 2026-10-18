extends Node2D
## Clock that runs 9:00–17:00 once per day, Monday to Friday.
## Each day is shorter in real time (set in day_lengths).
## Attach to the root clock node. Children must be HourPivot and MinutePivot
## (Node2Ds at the dial centre, each holding its hand sprite).

signal day_started(day_index: int, day_name: String)  # 0 = Monday ... 4 = Friday
signal day_over(day_index: int)                        # fires once at 5pm
signal week_over                                       # fires after Friday ends

## Real seconds for each day's 9–5. One entry per day.
@export var day_lengths: Array[float] = [60.0, 50.0, 40.0, 30.0, 20.0]
@export var day_names: Array[String] = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"]

@export var start_hour := 9.0
@export var end_hour := 17.0

## true = next day starts by itself after the pause (good for testing).
## false = clock waits at 5pm until something calls next_day() (e.g. a results screen).
@export var auto_advance := true
@export var pause_between_days := 2.0

## Speeds the whole week up while testing. 1 = normal, 5 = five times faster.
@export var test_speed := 1.0

## 0 = minute hand moves smoothly. 5 = it ticks in 5-minute steps.
@export var snap_minutes := 0
@export var debug_print := false  # prints the time each frame, for checking the maths

## Optional: drag a Label here in the Inspector to show the day name.
@export var day_label: Label

@onready var hour_hand: Node2D = $HourPivot
@onready var minute_hand: Node2D = $MinutePivot

var day_index := 0     # which day we're on: 0 = Monday
var elapsed := 0.0     # real seconds since 9:00 today
var running := false


func _ready() -> void:
	start_week()


func _process(delta: float) -> void:
	if not running:
		return

	elapsed += delta * test_speed

	if elapsed >= get_day_length():
		elapsed = get_day_length()   # clamp so the hands stop exactly on 5:00
		running = false              # flag: stops this block running every frame
		_update_hands()
		_end_day()
		return

	_update_hands()
	if debug_print:
		print(get_day_name(), " ", get_time_text())


# ---- Controlling the week --------------------------------------------------

## Back to Monday 9:00.
func start_week() -> void:
	day_index = 0
	start_day()


## Restart the current day from 9:00 (e.g. the player failed and retries).
func start_day() -> void:
	elapsed = 0.0
	running = true
	_update_hands()
	if day_label:
		day_label.text = get_day_name()
	print(get_day_name(), " starts (", get_day_length(), " seconds)")
	day_started.emit(day_index, get_day_name())


## Move on to tomorrow. After Friday, the week is over.
func next_day() -> void:
	day_index += 1
	if day_index >= day_lengths.size():
		running = false
		print("week over")
		week_over.emit()
		return
	start_day()


func _end_day() -> void:
	print(get_day_name(), " over")
	day_over.emit(day_index)
	if auto_advance:
		await get_tree().create_timer(pause_between_days).timeout
		next_day()


# ---- Reading the time --------------------------------------------------------

func get_day_length() -> float:
	return day_lengths[day_index]


func get_day_name() -> String:
	if day_index < day_names.size():
		return day_names[day_index]
	return "Day %d" % (day_index + 1)


## 0.0 at 9:00, 1.0 at 5pm. Use this later for sunrise/sunset too.
func get_progress() -> float:
	return clampf(elapsed / get_day_length(), 0.0, 1.0)


## Current game time in hours, e.g. 13.25 = 1:15pm.
func get_hours() -> float:
	return lerpf(start_hour, end_hour, get_progress())


## e.g. "1:15" — for printing or a digital display.
func get_time_text() -> String:
	var hours := get_hours()
	var h := int(hours)
	var m := int(fmod(hours, 1.0) * 60.0)
	var display_h := h % 12
	if display_h == 0:
		display_h = 12
	return "%d:%02d" % [display_h, m]


func _update_hands() -> void:
	var hours := get_hours()
	var minutes := fmod(hours, 1.0) * 60.0
	if snap_minutes > 0:
		minutes = floorf(minutes / snap_minutes) * snap_minutes

	# Hands are drawn pointing up (12 o'clock), so 0° = 12.
	hour_hand.rotation_degrees = fmod(hours, 12.0) * 30.0   # 30° per hour
	minute_hand.rotation_degrees = minutes * 6.0            # 6° per minute
