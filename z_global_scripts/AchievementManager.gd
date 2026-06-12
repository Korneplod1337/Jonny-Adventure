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
	#unlock_achievement('Alpha test')


func _on_stat_changed(stat_name: String, new_value: float) -> void:
	if not AchivStatsRegistry.TRACKING_ENABLED:
		return
	if stat_to_achievements.has(stat_name):
		for ach_key in stat_to_achievements[stat_name]:
			check_achievement(ach_key, new_value)


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
	var popup_path: String = ach["popup_window"]
	if popup_path != "":
		achievement_unlocked.emit(popup_path)
	save_achievements()


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
