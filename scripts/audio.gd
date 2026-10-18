extends AudioStreamPlayer


const PLUCKY_WALK_SONG = preload("uid://bgqggxayw1axn")

const BOARD_MEOW_ANGRY_1 = preload("uid://x5885t8ypv4y")
const BOARD_MEOW_ANGRY_2 = preload("uid://cai5p8kjofswv")

const JPC_MEOW_NEUTRAL_1 = preload("uid://dx27k0nodrumc")
const JPC_MEOW_NEUTRAL_2 = preload("uid://cxnq38jwovl7n")
const JPC_MEOW_NEUTRAL_3 = preload("uid://cbc8mp3p450q5")
const JPC_MEOW_NEUTRAL_4 = preload("uid://cpftea5bd15aj")

const BUTTON_PUSH_1 = preload("uid://dj88qblgoolki")
const BUTTON_PUSH_2 = preload("uid://6rotqdp5ncg8")
const BUTTON_PUSH_3 = preload("uid://bn1kphv231pvw")


var total_profit: float = 0.00

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

var button_push_list = [
	BUTTON_PUSH_1,
	BUTTON_PUSH_2,
	BUTTON_PUSH_3
]


func _play_music(music_stream: AudioStream, volume: float = -25.0) -> void:
	var music_player := AudioStreamPlayer.new()
	music_player.stream = music_stream
	music_player.name = "MUSIC_PLAYER"
	music_player.volume_db = volume

	add_child(music_player)
	music_player.play()

	await music_player.finished

	music_player.queue_free()


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

func fixed_music_player(fx_stream: AudioStream, volume: float = -15.0) -> void:
	if playing and stream == fx_stream:
		return

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

func play_button_push() -> void:
	var random_push: AudioStream = button_push_list.pick_random()
	_play_FX(random_push)
