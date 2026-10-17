extends AudioStreamPlayer

const PLUCKY_WALK_SONG = preload("uid://bgqggxayw1axn")

const BOARD_MEOW_ANGRY_1 = preload("uid://x5885t8ypv4y")
const BOARD_MEOW_ANGRY_2 = preload("uid://cai5p8kjofswv")

const JPC_MEOW_NEUTRAL_1 = preload("uid://dx27k0nodrumc")
const JPC_MEOW_NEUTRAL_2 = preload("uid://cxnq38jwovl7n")
const JPC_MEOW_NEUTRAL_3 = preload("uid://cbc8mp3p450q5")
const JPC_MEOW_NEUTRAL_4 = preload("uid://cpftea5bd15aj")

var meow_neutral_list = [
	JPC_MEOW_NEUTRAL_1,
	JPC_MEOW_NEUTRAL_2,
	JPC_MEOW_NEUTRAL_3,
	JPC_MEOW_NEUTRAL_4
]

var meow_angry_list = [
	BOARD_MEOW_ANGRY_1,
	BOARD_MEOW_ANGRY_2
]


func _play_music(music: AudioStream, volume: float = -25.0, fade_in: bool = false) -> void:
	if stream == music:
		return

	stream = music

	if fade_in:
		volume_db = -80.0
		play()
		fade_music_volume(volume)
	else:
		volume_db = volume
		play()


func fade_music_volume(target_db: float, duration: float = 1.0) -> void:
	var tween := create_tween()
	tween.tween_property(self, "volume_db", target_db, duration) \
		.set_trans(Tween.TRANS_SINE) \
		.set_ease(Tween.EASE_IN_OUT)


func _play_FX(fx_stream: AudioStream, volume: float = -15.0) -> void:
	var fx_player := AudioStreamPlayer.new()
	fx_player.stream = fx_stream
	fx_player.name = "FX_PLAYER"
	fx_player.volume_db = volume

	add_child(fx_player)
	fx_player.play()

	await fx_player.finished

	fx_player.queue_free()


func play_menu_music() -> void:
	_play_music(PLUCKY_WALK_SONG)


func play_neutral_meow() -> void:
	var random_meow: AudioStream = meow_neutral_list.pick_random()
	_play_FX(random_meow)


func play_angry_meow() -> void:
	var random_meow: AudioStream = meow_angry_list.pick_random()
	_play_FX(random_meow)
