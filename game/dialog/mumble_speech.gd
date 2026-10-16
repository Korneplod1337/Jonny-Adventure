class_name MumbleSpeech
extends RefCounted
## Синтетическая «мямлящая» речь по гласным латиницы A E I O U Y.

const VOWELS := "aeiouy"
const PITCH_MIN := 0.94
const PITCH_MAX := 1.06
## Клипы тихие — поднимаем на плеере (шина Dialog тоже чуть громче).
const VOICE_VOLUME_DB := 6.0
const VOICE_PATH := "res://sound/voices/%s_%s.wav"
## trader_id → префикс файла в sound/voices/
const VOICE_FILE_PREFIX := {
	"pepyaka": "pepyaka",
	"erik": "eric",
	"sherochka": "sher",
}

var _player: AudioStreamPlayer
var _streams: Dictionary = {} ## vowel -> AudioStream


func setup(player: AudioStreamPlayer) -> void:
	_player = player
	if _player:
		_player.bus = &"Dialog"
		_player.volume_db = VOICE_VOLUME_DB


func load_voice(trader_id: String) -> void:
	_streams.clear()
	if trader_id.is_empty():
		return
	var prefix: String = str(VOICE_FILE_PREFIX.get(trader_id, trader_id))
	for vowel in VOWELS:
		var path := VOICE_PATH % [prefix, vowel]
		if not ResourceLoader.exists(path):
			continue
		var stream: AudioStream = load(path) as AudioStream
		if stream:
			_streams[vowel] = stream



func on_char(ch: String) -> void:
	if ch.is_empty() or _player == null:
		return
	var key := ch.to_lower()
	if key.length() != 1 or not VOWELS.contains(key):
		return
	var stream: AudioStream = _streams.get(key) as AudioStream
	if stream == null:
		return
	_player.stop()
	_player.stream = stream
	_player.pitch_scale = randf_range(PITCH_MIN, PITCH_MAX)
	_player.play()


func stop() -> void:
	if _player and _player.playing:
		_player.stop()


## Пауза печати для символа. Точка внутри "..." считается как запятая (0.2).
static func pause_for_char_at(plain: String, index: int) -> float:
	if index < 0 or index >= plain.length():
		return 0.0
	var ch := plain.substr(index, 1)
	if ch.is_empty():
		return 0.0
	## ASCII троеточие: каждая "." рядом с другой "." → пауза запятой
	if ch == "." and _is_dot_in_ellipsis(plain, index):
		return 0.2
	match ch:
		",", "-", "—":
			return 0.2
		".", "!", "?", "…", ":", ";":
			return 0.4
		_:
			return 0.0


static func _is_dot_in_ellipsis(plain: String, index: int) -> bool:
	if plain.substr(index, 1) != ".":
		return false
	var prev_dot := index > 0 and plain.substr(index - 1, 1) == "."
	var next_dot := index + 1 < plain.length() and plain.substr(index + 1, 1) == "."
	return prev_dot or next_dot
