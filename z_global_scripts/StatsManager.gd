extends Node

const SAVE_PATH = "user://stats.cfg"

var stats := {}


signal stat_changed(stat_name: String, new_value: float)


func _ready() -> void:
	_init_stats_from_registry()
	load_statistic()


func _init_stats_from_registry() -> void:
	stats.clear()
	for key in AchivStatsRegistry.STATS.keys():
		var entry: Dictionary = AchivStatsRegistry.STATS[key]
		stats[key] = {
			"value": 0.0,
			"desc": entry.get("desc", key),
			"show_in_menu": entry.get("show_in_menu", false),
			"custom_display": entry.get("custom_display", ""),
		}


func load_statistic() -> void:
	var config = ConfigFile.new()
	if config.load(SAVE_PATH) == OK:
		for key in stats.keys():
			if config.has_section_key("stats", key):
				stats[key]["value"] = config.get_value("stats", key, 0)


func save_statistic() -> void:
	var config = ConfigFile.new()
	for key in stats.keys():
		config.set_value("stats", key, stats[key]["value"])
	config.save(SAVE_PATH)


func add_statistic_progress(key: String, value: float) -> void:
	if not AchivStatsRegistry.TRACKING_ENABLED:
		return
	if stats.has(key):
		stats[key]["value"] += value
		stat_changed.emit(key, stats[key]["value"])
		save_statistic()


func get_stat_display(key: String) -> Dictionary:
	return stats.get(key, {})


func get_menu_stat_keys() -> Array[String]:
	return AchivStatsRegistry.get_menu_stat_keys()
