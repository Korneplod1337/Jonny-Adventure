extends Node

## Прогресс медалей за прохождение локаций каждым персонажем
## и глобальный unlock локаций (общий для всех персонажей).
## user://character_medals.cfg
##   секция персонажа: medal_1 … medal_6, medal_final
##   секция _locations: max_unlocked (1…7)
## Windows: %APPDATA%\Godot\app_userdata\Jonny adventure\character_medals.cfg

const SAVE_PATH := "user://character_medals.cfg"
const LOCATIONS_SECTION := "_locations"
const MEDAL_COUNT := 7
const LOCATION_COUNT := 7
const DEFAULT_MAX_UNLOCKED_LOCATION := 1

## false = бета: все локации открыты, медали не выдаются, люк всегда ведёт дальше.
## true = релиз: гейт локаций, медали и экран победы на frontier.
const PROGRESSION_ENABLED := false

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
## 1-based: сколько локаций доступно глобально (1 = только подвал).
var _max_unlocked_location: int = DEFAULT_MAX_UNLOCKED_LOCATION


func _ready() -> void:
	load_medals()
	ensure_all_characters()


func get_all_character_ids() -> Array[String]:
	return CHARACTER_IDS.duplicate()


func get_save_path() -> String:
	return ProjectSettings.globalize_path(SAVE_PATH)


## 0-based индекс локации по этажу.
## Локация 1: этажи 0–3; дальше по 2 этажа на локацию.
func location_index_for_floor(floor_index: int) -> int:
	if floor_index < 4:
		return 0
	return int(floor_index - 2) / 2


func get_max_unlocked_location() -> int:
	if not PROGRESSION_ENABLED:
		return LOCATION_COUNT
	return _max_unlocked_location


func is_location_unlocked(location_1based: int) -> bool:
	if not PROGRESSION_ENABLED:
		return true
	return location_1based >= 1 and location_1based <= _max_unlocked_location


## Разблокирует локацию (1-based). Возвращает true, если это новый unlock.
func unlock_location(location_1based: int) -> bool:
	if not PROGRESSION_ENABLED:
		return false
	if location_1based < 1 or location_1based > LOCATION_COUNT:
		return false
	if location_1based <= _max_unlocked_location:
		return false
	_max_unlocked_location = location_1based
	save_medals()
	return true


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


## Выдаёт медаль за локацию (0-based: 0…5 малые, 6 — финальная).
func award_location_medal(character_id: String, location_0based: int) -> void:
	if not PROGRESSION_ENABLED:
		return
	if location_0based < 0 or location_0based >= MEDAL_COUNT:
		return
	set_medal(character_id, location_0based, true)


## Заготовка под будущие unlock’и персонажей/предметов через AchivementAndStatsRegistry.
## Пока ничего не делает.
func notify_location_completed(
	_character_id: String,
	_completed_location_1based: int,
	_newly_unlocked_next: bool
) -> void:
	if not PROGRESSION_ENABLED:
		return
	pass


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
		_max_unlocked_location = DEFAULT_MAX_UNLOCKED_LOCATION
		return
	_medals.clear()
	for section in config.get_sections():
		if section == LOCATIONS_SECTION:
			continue
		var entry: Array = []
		for i in range(6):
			entry.append(config.get_value(section, "medal_%d" % (i + 1), false))
		entry.append(config.get_value(section, "medal_final", false))
		_medals[section] = entry
	if config.has_section_key(LOCATIONS_SECTION, "max_unlocked"):
		_max_unlocked_location = clampi(
			int(config.get_value(LOCATIONS_SECTION, "max_unlocked", DEFAULT_MAX_UNLOCKED_LOCATION)),
			DEFAULT_MAX_UNLOCKED_LOCATION,
			LOCATION_COUNT
		)
	else:
		_max_unlocked_location = _infer_max_unlocked_from_medals()
		save_medals()


func _infer_max_unlocked_from_medals() -> int:
	var max_unlocked := DEFAULT_MAX_UNLOCKED_LOCATION
	for character_id in _medals.keys():
		var medals: Array = _medals[character_id]
		for i in medals.size():
			if not bool(medals[i]):
				continue
			# Прохождение локации i+1 открывает следующую (кроме финала).
			if i >= LOCATION_COUNT - 1:
				max_unlocked = maxi(max_unlocked, LOCATION_COUNT)
			else:
				max_unlocked = maxi(max_unlocked, i + 2)
	return clampi(max_unlocked, DEFAULT_MAX_UNLOCKED_LOCATION, LOCATION_COUNT)


func save_medals() -> void:
	var config := ConfigFile.new()
	for character_id in _medals.keys():
		for i in range(6):
			config.set_value(character_id, "medal_%d" % (i + 1), _medals[character_id][i])
		config.set_value(character_id, "medal_final", _medals[character_id][6])
	config.set_value(LOCATIONS_SECTION, "max_unlocked", _max_unlocked_location)
	config.save(SAVE_PATH)


func _ensure_character(character_id: String) -> void:
	if character_id.is_empty():
		return
	if not _medals.has(character_id):
		_medals[character_id] = []
		_medals[character_id].resize(MEDAL_COUNT)
		_medals[character_id].fill(false)
