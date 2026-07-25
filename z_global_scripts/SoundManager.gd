extends Node

const COIN_SFX := preload("res://sound/sound/coin_test.mp3")
const TRACK_ARCADE := preload("res://sound/music/arcade.ogg")
const TRACK_SOUNDTRACK_MB := preload("res://sound/music/soundtrack_mb.mp3")

const SFX_HEAL := preload("res://sound/sound/heal.mp3")
const SFX_HIT := preload("res://sound/sound/hit.mp3")
const SFX_HEARTBEAT := preload("res://sound/sound/heartbeat.mp3")
const SFX_WALKING := preload("res://sound/sound/walking.mp3")
const SFX_SHINE := preload("res://sound/sound/shine.mp3")
const SFX_MEGACRIT := preload("res://sound/sound/megacrit.mp3")
const SFX_REVIVE := preload("res://sound/sound/revive.mp3")
const SFX_DEATH := preload("res://sound/sound/death.mp3")

const SFX_SHOTS: Array[AudioStream] = [
	preload("res://sound/sound/shot1.mp3"),
	preload("res://sound/sound/shot2.mp3"),
	preload("res://sound/sound/shot3.mp3"),
	preload("res://sound/sound/shot4.mp3"),
]
const SFX_TEARS: Array[AudioStream] = [
	preload("res://sound/sound/shotTear1.mp3"),
	preload("res://sound/sound/shotTear2.mp3"),
	preload("res://sound/sound/shotTear3.mp3"),
	preload("res://sound/sound/shotTear4.mp3"),
]
const SFX_SLASHES: Array[AudioStream] = [
	preload("res://sound/sound/slash1.mp3"),
	preload("res://sound/sound/slash2.mp3"),
	preload("res://sound/sound/slash3.mp3"),
	preload("res://sound/sound/slash4.mp3"),
]

const LOOP_HEARTBEAT := &"heartbeat"
const LOOP_WALKING := &"walking"

## Относительные громкости SFX (дБ к дефолту 0). Master bus не трогаем.
const VOL_HEARTBEAT := 6.0
const VOL_GUN_SHOT := 3.5
const VOL_MEGACRIT := 4.0
const VOL_HIT := 6.0
const VOL_HEAL := 12.0
const VOL_SHINE := 4.0
const VOL_REVIVE := 4.0
const MUSIC_DEFAULT_DB := 0.0
const REVIVE_MUSIC_MUTE_HOLD_SEC := 5.0
const REVIVE_MUSIC_FADE_SEC := 5.0

## Плейлисты по индексу локации: массив словарей {stream, weight}.
## Локация 1 (index 0): arcade ~66%, soundtrack_mb ~33%.
## Остальные локации временно используют те же треки.
var _location_playlists: Dictionary = {}

const TRACK_SWITCH_SILENCE_SEC := 5.0

var _music_player: AudioStreamPlayer
var _current_location: int = -1
var _last_track: AudioStream = null
var _play_token: int = 0
var _loop_players: Dictionary = {}
var _music_duck_tween: Tween
var _music_duck_token: int = 0


func _ready() -> void:
	_music_player = AudioStreamPlayer.new()
	_music_player.name = "MusicPlayer"
	add_child(_music_player)
	_music_player.finished.connect(_on_music_finished)

	var location_1_playlist: Array = [
		{"stream": TRACK_ARCADE, "weight": 70},
		{"stream": TRACK_SOUNDTRACK_MB, "weight": 30},
	]
	# 7 локаций; 2+ пока с теми же треками — позже заменить через set_location_playlist
	for i in range(7):
		_location_playlists[i] = location_1_playlist.duplicate(true)


func play(stream: AudioStream, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	var player := AudioStreamPlayer.new()
	player.stream = stream
	player.volume_db = volume_db
	player.pitch_scale = pitch_scale
	add_child(player)
	player.finished.connect(player.queue_free, CONNECT_ONE_SHOT)
	player.play()


func play_random(streams: Array, volume_db: float = 0.0, pitch_scale: float = 1.0) -> void:
	if streams.is_empty():
		return
	play(streams[randi() % streams.size()], volume_db, pitch_scale)


func play_loop(key: StringName, stream: AudioStream, volume_db: float = 0.0) -> void:
	var existing: AudioStreamPlayer = _loop_players.get(key) as AudioStreamPlayer
	if existing and is_instance_valid(existing) and existing.playing:
		return

	stop_loop(key)
	var player := AudioStreamPlayer.new()
	var loop_stream := stream.duplicate()
	_enable_stream_loop(loop_stream)
	player.stream = loop_stream
	player.volume_db = volume_db
	player.name = "Loop_%s" % String(key)
	add_child(player)
	_loop_players[key] = player
	player.play()


func stop_loop(key: StringName) -> void:
	var player: AudioStreamPlayer = _loop_players.get(key) as AudioStreamPlayer
	_loop_players.erase(key)
	if player and is_instance_valid(player):
		player.stop()
		player.queue_free()


func play_heal() -> void:
	play(SFX_HEAL, VOL_HEAL)


func play_hit() -> void:
	play(SFX_HIT, VOL_HIT)


func play_shine() -> void:
	play(SFX_SHINE, VOL_SHINE)


func play_megacrit() -> void:
	play(SFX_MEGACRIT, VOL_MEGACRIT)


func play_revive() -> void:
	play(SFX_REVIVE, VOL_REVIVE)


func play_death() -> void:
	play(SFX_DEATH)


func duck_music_for_revive(
	mute_hold_sec: float = REVIVE_MUSIC_MUTE_HOLD_SEC,
	fade_sec: float = REVIVE_MUSIC_FADE_SEC
) -> void:
	if not is_instance_valid(_music_player):
		return
	_music_duck_token += 1
	var token := _music_duck_token
	if _music_duck_tween != null:
		_music_duck_tween.kill()
	_music_player.volume_db = -80.0
	_music_duck_tween = create_tween()
	_music_duck_tween.tween_interval(mute_hold_sec)
	_music_duck_tween.tween_method(
		func(v: float):
			if token != _music_duck_token or not is_instance_valid(_music_player):
				return
			_music_player.volume_db = v,
		-80.0,
		MUSIC_DEFAULT_DB,
		fade_sec
	)


func play_gun_shot() -> void:
	play_random(SFX_SHOTS, VOL_GUN_SHOT)


func play_tear_shot() -> void:
	play_random(SFX_TEARS)


func play_slash() -> void:
	play_random(SFX_SLASHES)


func start_heartbeat() -> void:
	play_loop(LOOP_HEARTBEAT, SFX_HEARTBEAT, VOL_HEARTBEAT)


func stop_heartbeat() -> void:
	stop_loop(LOOP_HEARTBEAT)


func start_walking() -> void:
	play_loop(LOOP_WALKING, SFX_WALKING)


func stop_walking() -> void:
	stop_loop(LOOP_WALKING)


func play_coins(count: int, delay: float = 0.1) -> void:
	for i in count:
		if i > 0:
			await get_tree().create_timer(delay).timeout
		play(COIN_SFX, 4.0, 0.9)


func play_location_music(location: int) -> void:
	if location == _current_location and _music_player.playing:
		return
	_current_location = location
	_play_weighted_track()


func stop_music() -> void:
	_play_token += 1
	_music_duck_token += 1
	_current_location = -1
	_last_track = null
	if _music_duck_tween != null:
		_music_duck_tween.kill()
		_music_duck_tween = null
	if _music_player.playing:
		_music_player.stop()
	_music_player.stream = null
	_music_player.volume_db = MUSIC_DEFAULT_DB


func set_location_playlist(location: int, playlist: Array) -> void:
	_location_playlists[location] = playlist


func _on_music_finished() -> void:
	if _current_location < 0:
		return
	_play_weighted_track()


func _play_weighted_track() -> void:
	var playlist: Array = _location_playlists.get(_current_location, [])
	if playlist.is_empty():
		stop_music()
		return

	var stream := _pick_weighted_stream(playlist)
	if stream == null:
		stop_music()
		return

	_play_token += 1
	var token := _play_token
	var needs_silence := _last_track != null and _last_track != stream
	if needs_silence:
		_music_player.stop()
		_music_player.stream = null
		await get_tree().create_timer(TRACK_SWITCH_SILENCE_SEC).timeout
		if token != _play_token or _current_location < 0:
			return

	_last_track = stream
	var play_stream := stream.duplicate()
	_disable_stream_loop(play_stream)
	_music_player.stop()
	_music_player.stream = play_stream
	_music_player.volume_db = MUSIC_DEFAULT_DB
	_music_player.play()


func _pick_weighted_stream(playlist: Array) -> AudioStream:
	var total_weight := 0
	for entry in playlist:
		total_weight += int(entry.get("weight", 0))
	if total_weight <= 0:
		return null

	var roll := randi() % total_weight
	var cumulative := 0
	for entry in playlist:
		cumulative += int(entry.get("weight", 0))
		if roll < cumulative:
			return entry.get("stream") as AudioStream
	return playlist[-1].get("stream") as AudioStream


func _disable_stream_loop(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = false
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = false
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_DISABLED


func _enable_stream_loop(stream: AudioStream) -> void:
	if stream is AudioStreamOggVorbis:
		(stream as AudioStreamOggVorbis).loop = true
	elif stream is AudioStreamMP3:
		(stream as AudioStreamMP3).loop = true
	elif stream is AudioStreamWAV:
		(stream as AudioStreamWAV).loop_mode = AudioStreamWAV.LOOP_FORWARD
