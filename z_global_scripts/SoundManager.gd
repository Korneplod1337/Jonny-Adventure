extends Node

const COIN_SFX := preload("res://sound/sound/coin_test.mp3")

func play(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	add_child(player)
	player.finished.connect(player.queue_free, CONNECT_ONE_SHOT)
	player.play()



func play_coins(count: int, delay: float = 0.1) -> void:
	for i in count:
		if i > 0:
			await get_tree().create_timer(delay).timeout
		play(COIN_SFX, 4.0, 0.9)
