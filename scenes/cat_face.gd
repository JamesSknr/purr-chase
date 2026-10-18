extends Node2D

@onready var animation_player: AnimationPlayer = $AnimationPlayer

var blink_timer: Timer

func _ready() -> void:
	if animation_player == null:
		push_error("AnimationPlayer not found!")
		return

	blink_timer = Timer.new()
	blink_timer.one_shot = true
	add_child(blink_timer)

	blink_timer.timeout.connect(_on_blink_timer_timeout)
	_schedule_next_blink()


func _schedule_next_blink() -> void:
	blink_timer.start(randf_range(2.0, 6.0))


func _on_blink_timer_timeout() -> void:
	if not animation_player.is_playing():
		animation_player.play("blink")

	_schedule_next_blink()
