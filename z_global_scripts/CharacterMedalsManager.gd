extends Node

## Прогресс медалей за прохождение локаций каждым персонажем.
## user://character_medals.cfg — секция на персонажа (medal_1 … medal_6, medal_final).
## Windows: %APPDATA%\Godot\app_userdata\Jonny adventure\character_medals.cfg

const SAVE_PATH := "user://character_medals.cfg"
const MEDAL_COUNT := 7

## Все персонажи с медалями прогресса локаций.
const CHARACTER_IDS: Array[String] = [
	"Jonny",
	"Jonnytta",
	"Jovita",
	"JonnyAlt",
	"JonnyttaAlt",
	"Jo",
	"John",
	"Joker",
	"Joab",
	"Joaquin",
]

var _medals: Dictionary = {}


func _ready() -> void:
	load_medals()
	ensure_all_characters()


func get_all_character_ids() -> Array[String]:
	return CHARACTER_IDS.duplicate()


func get_save_path() -> String:
	return ProjectSettings.globalize_path(SAVE_PATH)


func get_medals(character_id: String) -> Array:
	_ensure_character(character_id)
	return _medals[character_id].duplicate()


func is_medal_unlocked(character_id: String, index: int) -> bool:
	var medals := get_medals(character_id)
	if index < 0 or index >= medals.size():
		return false
	return medals[index]


func set_medal(character_id: String, index: int, unlocked: bool) -> void:
	_ensure_character(character_id)
	if index < 0 or index >= MEDAL_COUNT:
		return
	_medals[character_id][index] = unlocked
	save_medals()


func set_medals_for_character(character_id: String, medals: Array) -> void:
	_ensure_character(character_id)
	for i in mini(medals.size(), MEDAL_COUNT):
		_medals[character_id][i] = bool(medals[i])
	save_medals()


## Создаёт файл и пустые записи для всех персонажей, если их ещё нет.
func ensure_all_characters() -> void:
	ensure_characters(CHARACTER_IDS)


## Добавляет записи для переданных id + всех из CHARACTER_IDS.
func ensure_characters(character_ids: Array = []) -> void:
	var changed := not FileAccess.file_exists(SAVE_PATH)
	var all_ids: Array[String] = []
	for id in CHARACTER_IDS:
		all_ids.append(id)
	for id in character_ids:
		var character_id := str(id)
		if character_id.is_empty() or character_id in all_ids:
			continue
		all_ids.append(character_id)
	for character_id in all_ids:
		if not _medals.has(character_id):
			_ensure_character(character_id)
			changed = true
	if changed:
		save_medals()


func load_medals() -> void:
	var config := ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	for section in config.get_sections():
		var entry: Array = []
		for i in range(6):
			entry.append(config.get_value(section, "medal_%d" % (i + 1), false))
		entry.append(config.get_value(section, "medal_final", false))
		_medals[section] = entry


func save_medals() -> void:
	var config := ConfigFile.new()
	for character_id in _medals.keys():
		for i in range(6):
			config.set_value(character_id, "medal_%d" % (i + 1), _medals[character_id][i])
		config.set_value(character_id, "medal_final", _medals[character_id][6])
	config.save(SAVE_PATH)


func _ensure_character(character_id: String) -> void:
	if character_id.is_empty():
		return
	if not _medals.has(character_id):
		_medals[character_id] = []
		_medals[character_id].resize(MEDAL_COUNT)
		_medals[character_id].fill(false)
