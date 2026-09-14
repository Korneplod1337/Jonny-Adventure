extends Node

const SAVE_PATH = "user://achievements.cfg"

var achievements := {}
var stat_to_achievements := {}


signal achievement_unlocked(data: String)


func _ready() -> void:
	achievements = AchivStatsRegistry.build_achievements_data()
	stat_to_achievements = AchivStatsRegistry.build_stat_to_achievements()
	load_achievements()
	StatsManager.stat_changed.connect(_on_stat_changed)
	# StatsManager грузится после нас — перепроверяем пороги на следующем кадре.
	call_deferred("_recheck_stat_achievements")
	call_deferred("_apply_location_unlocks_from_achievements")
	#unlock_achievement('Alpha test')


func _apply_location_unlocks_from_achievements() -> void:
	for ach_id in AchivStatsRegistry.LOCATION_UNLOCKS.keys():
		if not is_unlocked(ach_id):
			continue
		var loc: int = int(AchivStatsRegistry.LOCATION_UNLOCKS[ach_id])
		CharacterMedalsManager.unlock_location(loc)

func _on_stat_changed(stat_name: String, new_value: float) -> void:
	if not AchivStatsRegistry.TRACKING_ENABLED:
		return
	if stat_to_achievements.has(stat_name):
		for ach_key in stat_to_achievements[stat_name]:
			check_achievement(ach_key, new_value)


func _recheck_stat_achievements() -> void:
	for stat_name in stat_to_achievements.keys():
		var stat_data: Dictionary = StatsManager.get_stat_display(stat_name)
		var value := float(stat_data.get("value", 0.0))
		for ach_key in stat_to_achievements[stat_name]:
			check_achievement(ach_key, value)


func check_achievement(key: String, stat_value: float) -> void:
	var ach = achievements.get(key)
	if ach and not ach["unlocked"] and stat_value >= ach["goal"]:
		unlock_achievement(key)


func unlock_achievement(key: String) -> void:
	if not AchivStatsRegistry.TRACKING_ENABLED:
		return
	var ach = achievements.get(key)
	if not ach or ach["unlocked"]:
		return
	ach["unlocked"] = true
	save_achievements()
	if AchivStatsRegistry.LOCATION_UNLOCKS.has(key):
		var loc: int = int(AchivStatsRegistry.LOCATION_UNLOCKS[key])
		CharacterMedalsManager.unlock_location(loc)
	# Всегда уведомляем слушателей (ItemManager / EquipManager / меню).
	# HUD сам игнорирует пустой путь и "-".
	achievement_unlocked.emit(ach["popup_window"])



func is_unlocked(key: String) -> bool:
	var ach = achievements.get(key)
	return ach.get("unlocked", false) if ach else false


func load_achievements() -> void:
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) != OK:
		return
	for key in achievements.keys():
		achievements[key]["unlocked"] = config.get_value("achievements", key + "_unlocked", false)


func save_achievements() -> void:
	var config = ConfigFile.new()
	for key in achievements.keys():
		config.set_value("achievements", key + "_unlocked", achievements[key]["unlocked"])
	config.save(SAVE_PATH)
